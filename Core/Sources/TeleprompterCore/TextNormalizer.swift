import Foundation

/// Palavras comparáveis entre o roteiro e o que o reconhecimento de fala devolve:
/// minúsculas, sem acento, sem pontuação. "Você" e "voce" viram a mesma coisa.
public enum TextNormalizer {
    static let wordPattern = try! NSRegularExpression(pattern: "[\\p{L}\\p{N}]+")
    static let locale = Locale(identifier: "pt_BR")

    public static func normalize(_ word: String) -> String {
        word.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: locale)
            .lowercased()
    }

    /// Palavras normalizadas de um texto, na ordem.
    public static func words(in text: String) -> [String] {
        let ns = text as NSString
        return wordPattern.matches(in: text, range: NSRange(location: 0, length: ns.length))
            .map { normalize(ns.substring(with: $0.range)) }
    }

    public static func isNumber(_ normalized: String) -> Bool {
        !normalized.isEmpty && normalized.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    /// Distância de edição (Levenshtein), limitada: devolve `limit + 1` assim que passa do limite.
    public static func editDistance(_ a: String, _ b: String, limit: Int) -> Int {
        let a = Array(a), b = Array(b)
        if abs(a.count - b.count) > limit { return limit + 1 }
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            var rowMin = current[0]
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                rowMin = min(rowMin, current[j])
            }
            if rowMin > limit { return limit + 1 }
            swap(&previous, &current)
        }
        return previous[b.count]
    }

    /// Duas palavras "batem" se forem iguais ou quase iguais. O reconhecimento erra letra em palavra
    /// longa ("repositorio"/"repositório" já some na normalização; "cliente"/"clientes" não).
    public static func fuzzyEqual(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        let shorter = min(a.count, b.count)
        guard shorter >= 4 else { return false }
        let limit = shorter >= 8 ? 2 : 1
        if editDistance(a, b, limit: limit) <= limit { return true }
        // Prefixo comum longo (o reconhecimento às vezes corta o fim da palavra).
        if shorter >= 5, a.hasPrefix(b) || b.hasPrefix(a) { return true }
        return false
    }
}
