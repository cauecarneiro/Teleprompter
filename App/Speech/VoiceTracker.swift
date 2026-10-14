import AVFoundation
import Speech

/// Reconhecimento de voz em português, no próprio iPhone quando o aparelho suporta.
/// Recebe o mesmo áudio que vai para o vídeo (da câmera) e devolve o texto ouvido até agora.
///
/// O iOS encerra a tarefa de reconhecimento depois de um tempo ou de um silêncio longo; aqui ela
/// recomeça sozinha. Se falhar várias vezes seguidas sem ouvir nada, para e avisa.
final class VoiceTracker: @unchecked Sendable {
    enum Status: Equatable { case off, listening, unavailable, denied }

    private let lock = NSLock()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var running = false
    private var consecutiveFailures = 0
    private var generation = 0
    /// Depois de falhar no aparelho (modelo de português não baixado), tenta pelo servidor da Apple.
    private var allowServer = false

    /// Palavras raras do roteiro (nomes, marcas) para o reconhecimento acertar mais.
    var contextualStrings: [String] = []
    /// Texto ouvido na tarefa atual (cresce até a tarefa recomeçar). Chamado fora do MainActor.
    var onTranscript: (@Sendable (String) -> Void)?
    /// Mudança de estado. Chamado fora do MainActor.
    var onStatus: (@Sendable (Status) -> Void)?

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
    }

    static var isAuthorized: Bool { SFSpeechRecognizer.authorizationStatus() == .authorized }

    var isOnDevice: Bool { recognizer?.supportsOnDeviceRecognition ?? false }

    func start() {
        lock.lock()
        running = true
        consecutiveFailures = 0
        lock.unlock()
        beginTask()
    }

    func stop() {
        lock.lock()
        running = false
        generation += 1
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        lock.unlock()
        onStatus?(.off)
    }

    /// Recomeça do zero (depois de pular de seção, o texto antigo não deve puxar a posição).
    func restart() {
        lock.lock()
        let wasRunning = running
        generation += 1
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        lock.unlock()
        if wasRunning { beginTask() }
    }

    /// Chamado no fila de áudio da câmera.
    func append(_ sample: CMSampleBuffer) {
        lock.lock()
        let current = request
        lock.unlock()
        current?.appendAudioSampleBuffer(sample)
    }

    private func beginTask() {
        guard let recognizer, recognizer.isAvailable else {
            onStatus?(.unavailable)
            return
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.addsPunctuation = false
        lock.lock()
        let server = allowServer
        lock.unlock()
        if recognizer.supportsOnDeviceRecognition, !server { request.requiresOnDeviceRecognition = true }
        request.contextualStrings = Array(contextualStrings.prefix(100))

        lock.lock()
        guard running else { lock.unlock(); return }
        generation += 1
        let myGeneration = generation
        self.request = request
        lock.unlock()

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            self.lock.lock()
            let isCurrent = myGeneration == self.generation
            self.lock.unlock()
            guard isCurrent else { return }

            if let result {
                self.lock.lock(); self.consecutiveFailures = 0; self.lock.unlock()
                self.onTranscript?(result.bestTranscription.formattedString)
            }
            if error != nil || result?.isFinal == true {
                self.finishTask(failed: result == nil)
            }
        }
        lock.lock()
        self.task = task
        lock.unlock()
        onStatus?(.listening)
    }

    private func finishTask(failed: Bool) {
        lock.lock()
        request = nil
        task = nil
        if failed { consecutiveFailures += 1 }
        if consecutiveFailures >= 2 { allowServer = true }
        let shouldRestart = running && consecutiveFailures < 6
        let delay = failed ? min(2.0, 0.3 * Double(consecutiveFailures)) : 0.05
        if !shouldRestart && running { running = false }
        lock.unlock()

        if shouldRestart {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.beginTask()
            }
        } else {
            onStatus?(.unavailable)
        }
    }
}
