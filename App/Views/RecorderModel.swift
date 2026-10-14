import AVFoundation
import Observation
import SwiftData
import TeleprompterCore
import UIKit

/// Tudo o que acontece na tela de gravação: câmera, contagem, gravar e salvar, voz e texto.
@MainActor
@Observable
final class RecorderModel {
    enum Phase: Equatable { case idle, countdown(Int), recording, saving }

    let script: Script
    let settings: PrompterSettings
    let prompter = PrompterController()
    @ObservationIgnored let camera = CameraController()
    @ObservationIgnored let voice = VoiceTracker()

    private(set) var phase: Phase = .idle
    private(set) var recordingStartedAt: Date?
    private(set) var audioLevel: Float = 0
    private(set) var cameraReady = false
    private(set) var cameraDenied = false
    /// Falso quando não há câmera (simulador) ou na demonstração.
    private(set) var cameraExpected = true
    private(set) var microphoneDenied = false
    private(set) var voiceStatus: VoiceTracker.Status = .off
    var toast: ToastMessage?
    private(set) var parsed: ParsedScript

    @ObservationIgnored private var countdownTask: Task<Void, Never>?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var takeSectionIndex = 0
    @ObservationIgnored private var started = false
    @ObservationIgnored private weak var context: ModelContext?

    var isRecording: Bool { phase == .recording }
    var isBusy: Bool { phase != .idle }

    init(script: Script, settings: PrompterSettings = .shared) {
        self.script = script
        self.settings = settings
        self.parsed = script.parsed
        prompter.mode = settings.scrollMode
        prompter.wordsPerMinute = settings.wordsPerMinute
        wireCallbacks()
    }

    private func wireCallbacks() {
        let voice = voice
        camera.onAudioSample = { sample in voice.append(sample) }
        camera.onAudioLevel = { [weak self] level in self?.audioLevel = level }
        camera.onInterrupted = { [weak self] in
            guard let self, self.isRecording else { return }
            self.stopRecording()
        }
        voice.onTranscript = { [weak self] text in
            Task { @MainActor in self?.prompter.heard(text) }
        }
        voice.onStatus = { [weak self] status in
            Task { @MainActor in self?.voiceStatus = status }
        }
        prompter.onUserScrolled = { [weak self] in
            guard let self, self.prompter.mode == .voice else { return }
            self.voice.restart()
        }
    }

    // MARK: Abrir e fechar

    func start(context: ModelContext) {
        self.context = context
        guard !started else {
            camera.startSession()
            return
        }
        started = true
        UIApplication.shared.isIdleTimerDisabled = true
        Task {
            // Sem câmera (simulador), não pede acesso: o aviso do iOS só atrapalharia.
            var wantsCamera = CameraController.isAvailable
            #if DEBUG
            if DemoMode.isOn { wantsCamera = false }
            #endif
            cameraExpected = wantsCamera
            let video = wantsCamera ? await AVCaptureDevice.requestAccess(for: .video) : false
            let audio = wantsCamera ? await AVCaptureDevice.requestAccess(for: .audio) : false
            cameraDenied = wantsCamera && !video
            microphoneDenied = wantsCamera && !audio
            if video, CameraController.isAvailable {
                camera.configure(settings.cameraConfiguration) { ok in
                    self.cameraReady = ok
                }
            }
            if wantsCamera { await PhotoSaver.prepare(album: settings.saveToAlbum) }
            if prompter.mode == .voice { await startVoice() }
            #if DEBUG
            if DemoMode.plays {
                try? await Task.sleep(for: .seconds(1))
                prompter.mode = .auto
                prompter.play()
            }
            #endif
        }
    }

    func stop() {
        countdownTask?.cancel()
        if isRecording { stopRecording() }
        voice.stop()
        camera.stopSession()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func appDidEnterBackground() {
        countdownTask?.cancel()
        if case .countdown = phase { phase = .idle }
        if isRecording { stopRecording() }
        prompter.pause()
    }

    func appDidBecomeActive() {
        guard started else { return }
        camera.startSession()
    }

    func reconfigureCamera() {
        guard !isBusy, CameraController.isAvailable, !cameraDenied else { return }
        cameraReady = false
        camera.configure(settings.cameraConfiguration) { [weak self] ok in
            self?.cameraReady = ok
        }
    }

    // MARK: Modo e velocidade

    func cycleMode() {
        setMode(prompter.mode.next)
    }

    func setMode(_ mode: ScrollMode) {
        prompter.mode = mode
        settings.scrollMode = mode
        Haptics.tap()
        if mode == .voice {
            Task { await startVoice() }
        } else {
            voice.stop()
        }
        if mode == .manual { prompter.pause() }
        showToast(ToastMessage(text: modeHint(mode), icon: mode.icon))
    }

    private func modeHint(_ mode: ScrollMode) -> String {
        switch mode {
        case .auto: "Automático: \(Int(prompter.wordsPerMinute)) palavras por minuto"
        case .voice: "Voz: o texto anda quando você fala"
        case .manual: "Manual: role com o dedo"
        }
    }

    func faster() { prompter.faster(); settings.wordsPerMinute = prompter.wordsPerMinute; Haptics.tick() }
    func slower() { prompter.slower(); settings.wordsPerMinute = prompter.wordsPerMinute; Haptics.tick() }

    private func startVoice() async {
        if !VoiceTracker.isAuthorized {
            let ok = await VoiceTracker.requestAuthorization()
            guard ok else {
                voiceStatus = .denied
                showToast(ToastMessage(text: "Sem permissão de reconhecimento de fala. Ative em Ajustes.", icon: "waveform.slash", isWarning: true))
                return
            }
        }
        guard prompter.mode == .voice else { return }
        voice.contextualStrings = Self.rareWords(in: parsed)
        voice.start()
    }

    /// Nomes e palavras longas do roteiro: ajudam o reconhecimento a acertar marcas e termos.
    static func rareWords(in script: ParsedScript) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for section in script.sections {
            let ns = section.body as NSString
            for token in section.tokens where token.isTrackable {
                let word = ns.substring(with: token.range)
                let isName = word.first?.isUppercase == true
                guard isName || word.count >= 8, seen.insert(token.normalized).inserted else { continue }
                result.append(word)
            }
        }
        return Array(result.prefix(100))
    }

    // MARK: Gravar

    func recordTapped() {
        switch phase {
        case .idle:
            beginCountdown()
        case .countdown:
            countdownTask?.cancel()
            phase = .idle
            Haptics.tap()
        case .recording:
            stopRecording()
        case .saving:
            break
        }
    }

    private func beginCountdown() {
        guard cameraReady else {
            if cameraDenied {
                showToast(ToastMessage(text: "Sem acesso à câmera. Ative em Ajustes > Teleprompter.", icon: "video.slash", isWarning: true))
            } else if !CameraController.isAvailable {
                showToast(ToastMessage(text: "Câmera indisponível neste aparelho.", icon: "video.slash", isWarning: true))
            }
            return
        }
        let seconds = settings.countdown
        guard seconds > 0 else { startRecording(); return }
        prompter.pause()
        countdownTask = Task {
            for value in stride(from: seconds, through: 1, by: -1) {
                phase = .countdown(value)
                Haptics.tick()
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
            startRecording()
        }
    }

    private func startRecording() {
        takeSectionIndex = prompter.currentSection
        phase = .recording
        recordingStartedAt = Date()
        Haptics.heavy()
        camera.onRecordingStarted = { [weak self] in
            self?.recordingStartedAt = Date()
        }
        camera.startRecording()
        if settings.scrollStartsWithRecording, prompter.mode != .manual {
            prompter.play()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        phase = .saving
        prompter.pause()
        Haptics.heavy()
        let sectionIndex = takeSectionIndex
        let sectionTitle = prompter.sections.indices.contains(sectionIndex) ? prompter.sections[sectionIndex].title : ""
        camera.stopRecording { [weak self] result in
            guard let self else { return }
            self.recordingStartedAt = nil
            switch result {
            case .success(let take):
                Task { await self.save(take, sectionTitle: sectionTitle) }
            case .failure(let error):
                self.phase = .idle
                Haptics.error()
                self.showToast(ToastMessage(text: error.localizedDescription, icon: "exclamationmark.triangle.fill", isWarning: true))
            }
        }
    }

    private func save(_ take: RecordedTake, sectionTitle: String) async {
        let hasAudio = await Self.hasAudio(take.url)
        do {
            let album = settings.saveToAlbum ? PrompterSettings.albumName : nil
            let identifier = try await PhotoSaver.save(videoAt: take.url, albumName: album)
            let record = Take(sectionTitle: sectionTitle, duration: take.duration, assetIdentifier: identifier)
            script.takes.append(record)
            script.updatedAt = Date()
            try? context?.save()
            phase = .idle
            if hasAudio {
                Haptics.success()
                let canRedo = prompter.sections.count > 1
                showToast(ToastMessage(
                    text: "Salvo na galeria · \(clockLabel(take.duration))",
                    actionTitle: canRedo ? "Refazer" : nil
                ), seconds: 4)
            } else {
                Haptics.error()
                showToast(ToastMessage(text: "Salvo, mas sem áudio. Confira o microfone.", icon: "mic.slash.fill", isWarning: true), seconds: 5)
            }
        } catch {
            phase = .idle
            Haptics.error()
            try? FileManager.default.removeItem(at: take.url)
            showToast(ToastMessage(text: error.localizedDescription, icon: "exclamationmark.triangle.fill", isWarning: true), seconds: 5)
        }
    }

    private static func hasAudio(_ url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        let tracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
        return !tracks.isEmpty
    }

    /// "Refazer": volta para o começo da seção em que o último take começou.
    func redoLastSection() {
        toast = nil
        prompter.jump(toSection: takeSectionIndex)
    }

    // MARK: Avisos

    func showToast(_ message: ToastMessage, seconds: Double = 2.2) {
        toastTask?.cancel()
        toast = message
        toastTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled { toast = nil }
        }
    }

    // MARK: Foco

    func focus(devicePoint: CGPoint, lock: Bool) {
        camera.focus(at: devicePoint, lock: lock)
        if lock { Haptics.heavy() } else { Haptics.tap() }
    }

    /// Segundos que faltam para terminar o texto no ritmo atual.
    var remainingSeconds: Double {
        let words = Double(parsed.wordCount) * (1 - prompter.progress)
        return words / max(1, prompter.wordsPerMinute) * 60
    }
}
