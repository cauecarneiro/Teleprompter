import Foundation

/// Acompanha a fala no roteiro: recebe o que o reconhecimento de voz ouviu e diz qual é a próxima
/// palavra a ler.
///
/// Como decide (alinhamento local, no estilo Smith-Waterman, só numa janela em volta da posição):
/// - pega as últimas palavras ouvidas (até `tailLength`) e procura onde elas batem no roteiro,
///   de `lookBehind` palavras para trás até `lookAhead` para a frente;
/// - palavra que bate soma pontos, palavra trocada ou pulada tira; precisa de pelo menos duas
///   palavras batendo para mexer;
/// - para a frente basta o mínimo; **para trás** (ele errou e repetiu a frase) exige três palavras
///   batendo, para uma palavra comum ("que", "de") não fazer o texto voltar à toa;
/// - improviso que não bate com nada deixa a posição parada.
public final class VoiceMatcher {
    public struct Configuration: Sendable {
        public var tailLength = 8
        public var lookBehind = 30
        public var lookAhead = 60
        public var matchScore = 2
        public var mismatchPenalty = 1
        public var gapPenalty = 1
        /// Pontuação mínima para andar para a frente (duas palavras batendo = 4).
        public var forwardThreshold = 4
        /// Pontuação mínima para voltar (três palavras batendo = 6).
        public var backwardThreshold = 6
        public init() {}
    }

    public let words: [String]
    public private(set) var position: Int
    public var configuration: Configuration

    /// `words`: as palavras acompanháveis do roteiro, já normalizadas e na ordem.
    public init(words: [String], configuration: Configuration = .init()) {
        self.words = words
        self.position = 0
        self.configuration = configuration
    }

    public func reset(to position: Int) {
        self.position = max(0, min(position, words.count))
    }

    /// Recebe a transcrição (parcial ou final) e devolve a nova posição, se mudou.
    @discardableResult
    public func update(transcript: String) -> Int? {
        let heard = TextNormalizer.words(in: transcript).filter { !TextNormalizer.isNumber($0) }
        return update(heardWords: heard)
    }

    @discardableResult
    public func update(heardWords: [String]) -> Int? {
        guard !words.isEmpty, !heard(heardWords).isEmpty else { return nil }
        let tail = Array(heardWords.suffix(configuration.tailLength))
        let lower = max(0, position - configuration.lookBehind)
        let upper = min(words.count, position + configuration.lookAhead)
        guard lower < upper else { return nil }
        let window = Array(words[lower..<upper])

        guard let best = align(tail: tail, window: window) else { return nil }
        let newPosition = lower + best.endIndex + 1
        if newPosition == position { return nil }
        let threshold = newPosition > position ? configuration.forwardThreshold : configuration.backwardThreshold
        guard best.score >= threshold else { return nil }
        position = newPosition
        return newPosition
    }

    private func heard(_ words: [String]) -> [String] { words.filter { !$0.isEmpty } }

    /// Melhor alinhamento que termina numa das duas últimas palavras ouvidas.
    /// Devolve o índice (na janela) da palavra do roteiro onde o alinhamento termina.
    private func align(tail: [String], window: [String]) -> (score: Int, endIndex: Int)? {
        let m = tail.count, n = window.count
        guard m > 0, n > 0 else { return nil }
        let c = configuration
        var previous = [Int](repeating: 0, count: n + 1)
        var current = [Int](repeating: 0, count: n + 1)
        var best: (score: Int, endIndex: Int)?

        for i in 1...m {
            current[0] = 0
            for j in 1...n {
                let isMatch = TextNormalizer.fuzzyEqual(tail[i - 1], window[j - 1])
                let diagonal = previous[j - 1] + (isMatch ? c.matchScore : -c.mismatchPenalty)
                let up = previous[j] - c.gapPenalty      // palavra ouvida que não está no roteiro
                let left = current[j - 1] - c.gapPenalty // palavra do roteiro que ele pulou
                current[j] = max(0, diagonal, up, left)
                // Só conta alinhamento que termina numa palavra que bateu, e nas últimas palavras ouvidas.
                if isMatch, i >= m - 1, current[j] == diagonal {
                    let candidate = (score: current[j], endIndex: j - 1)
                    if let b = best {
                        // Empate: fica com o que está mais perto da posição atual (para a frente).
                        if candidate.score > b.score
                            || (candidate.score == b.score && closeness(candidate.endIndex) < closeness(b.endIndex)) {
                            best = candidate
                        }
                    } else {
                        best = candidate
                    }
                }
            }
            swap(&previous, &current)
        }
        return best
    }

    /// Distância de uma posição da janela até a posição atual (usada só no desempate).
    private func closeness(_ windowIndex: Int) -> Int {
        let lower = max(0, position - configuration.lookBehind)
        let absolute = lower + windowIndex + 1
        return absolute >= position ? absolute - position : (position - absolute) * 2
    }
}
