import Observation
import TeleprompterCore
import UIKit

/// O que a tela de gravação usa para mandar no texto: tocar, pausar, pular de seção,
/// receber a voz. O desenho e a rolagem ficam em `PrompterTextView`.
@MainActor
@Observable
final class PrompterController {
    private(set) var isPlaying = false
    private(set) var currentSection = 0
    /// 0 a 1: quanto do texto já passou pela linha de leitura.
    private(set) var progress: Double = 0
    private(set) var reachedEnd = false
    /// Seções do roteiro na ordem da tela.
    private(set) var sections: [ScriptSection] = []

    var mode: ScrollMode = .auto {
        didSet {
            guard mode != oldValue else { return }
            view?.modeChanged()
            if mode == .voice { resyncVoice() }
        }
    }
    var wordsPerMinute: Double = 150

    /// O texto foi arrastado à mão (para o modo Voz recomeçar a ouvir dali).
    @ObservationIgnored var onUserScrolled: (() -> Void)?

    @ObservationIgnored weak var view: PrompterTextView?
    @ObservationIgnored private(set) var matcher: VoiceMatcher?
    @ObservationIgnored private(set) var voicePosition = 0

    // MARK: Comandos

    func play() {
        guard mode != .manual else { return }
        if reachedEnd { restart() }
        isPlaying = true
        view?.playbackChanged()
    }

    func pause() {
        isPlaying = false
        view?.playbackChanged()
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func restart() {
        reachedEnd = false
        jump(toSection: 0)
    }

    func jump(toSection index: Int) {
        guard let view, view.document?.sections.indices.contains(index) == true else { return }
        reachedEnd = false
        view.scroll(toSection: index, animated: true)
        if let mark = view.document?.sections[index] {
            setVoicePosition(mark.firstToken)
        }
        currentSection = index
        onUserScrolled?()
    }

    /// Anda uma linha para cima (−1) ou para baixo (+1). Teclado e controle Bluetooth.
    func nudge(lines: Int) {
        view?.nudge(lines: lines)
        resyncVoice()
    }

    func faster() { wordsPerMinute = min(260, wordsPerMinute + 10) }
    func slower() { wordsPerMinute = max(80, wordsPerMinute - 10) }

    // MARK: Voz

    /// Texto ouvido pelo reconhecimento (no MainActor).
    func heard(_ transcript: String) {
        guard mode == .voice, let matcher else { return }
        if let position = matcher.update(transcript: transcript) {
            voicePosition = position
            view?.voicePositionChanged()
        }
    }

    // MARK: Avisos da view

    func documentLoaded(_ document: PrompterDocument) {
        sections = document.sections.map(\.section)
        matcher = VoiceMatcher(words: document.trackableWords)
        matcher?.reset(to: voicePosition)
    }

    func report(section: Int, progress: Double) {
        if section != currentSection { currentSection = section }
        if abs(progress - self.progress) > 0.002 { self.progress = progress }
    }

    func didReachEnd() {
        reachedEnd = true
        isPlaying = false
        view?.playbackChanged()
    }

    func userDidScroll() {
        reachedEnd = false
        resyncVoice()
        onUserScrolled?()
    }

    private func resyncVoice() {
        guard let view, let token = view.tokenAtReadingLine() else { return }
        setVoicePosition(token)
    }

    private func setVoicePosition(_ token: Int) {
        voicePosition = token
        matcher?.reset(to: token)
    }
}
