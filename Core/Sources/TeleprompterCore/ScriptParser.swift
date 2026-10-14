import Foundation

/// Uma palavra do corpo de uma seção, com o lugar dela no texto (em UTF-16, para o UIKit).
public struct ScriptToken: Sendable, Hashable {
    /// Posição dentro do `body` da seção.
    public let range: NSRange
    public let normalized: String
    /// Fica fora do acompanhamento por voz: indicação entre parênteses ou número escrito em algarismos.
    public let isTrackable: Bool
}

public struct ScriptSection: Sendable, Identifiable, Hashable {
    public let id: Int
    /// Título como veio no roteiro ("ABERTURA UM"). Vazio para o texto antes do primeiro título.
    public let title: String
    /// O que estava entre parênteses no título ("grave por último").
    public let note: String?
    /// O texto falado, com as indicações entre parênteses mantidas para exibir em cinza.
    public let body: String
    public let tokens: [ScriptToken]
    /// Trechos entre parênteses dentro do corpo (indicações de cena).
    public let directionRanges: [NSRange]

    /// "ABERTURA UM" → "Abertura um". Vazio → "Início".
    public var displayTitle: String {
        guard !title.isEmpty else { return "Início" }
        let lower = title.lowercased(with: Locale(identifier: "pt_BR"))
        return lower.prefix(1).uppercased(with: Locale(identifier: "pt_BR")) + lower.dropFirst()
    }

    public var hasSpeech: Bool { !tokens.isEmpty }
    public var wordCount: Int { tokens.filter { !$0.isDirection }.count }
}

extension ScriptToken {
    var isDirection: Bool { !isTrackable && !TextNormalizer.isNumber(normalized) }
}

public struct ParsedScript: Sendable, Hashable {
    public let sections: [ScriptSection]

    /// Palavras ditas (sem indicações de cena), para estimar o tempo.
    public var wordCount: Int { sections.reduce(0) { $0 + $1.wordCount } }

    /// Seções que têm fala: as que viram atalho na tela de gravação.
    public var speakingSections: [ScriptSection] { sections.filter(\.hasSpeech) }

    /// Título curto para a lista: as primeiras palavras da primeira fala.
    public var suggestedTitle: String {
        guard let first = sections.first(where: \.hasSpeech) else { return "Roteiro" }
        let text = first.body
            .replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?m)^\\s*\\d+[.)]\\s+", with: "", options: .regularExpression)
        let all = text.split(whereSeparator: \.isWhitespace)
        let words = all.prefix(7).joined(separator: " ")
        let trimmed = words.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
        guard !trimmed.isEmpty else { return "Roteiro" }
        let capitalized = trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        return all.count > 7 ? capitalized + "…" : capitalized
    }
}

/// Lê o texto colado (o bloco "Teleprompter" do Notion ou qualquer texto solto).
///
/// Regras:
/// - Linha em CAIXA ALTA (ignorando o que está entre parênteses) é título de seção: "ABERTURA UM",
///   "FECHO DOIS (envio)". Linha que começa com `#` também.
/// - O que está entre parênteses no corpo é indicação de cena: aparece em cinza e não entra no
///   acompanhamento por voz.
/// - Marcas de Markdown (```, **, > , - [ ]) somem.
/// - Texto sem nenhum título vira uma seção só.
public enum ScriptParser {
    static let parenthetical = try! NSRegularExpression(pattern: "\\([^)]*\\)")

    public static func parse(_ raw: String) -> ParsedScript {
        var sections: [ScriptSection] = []
        var currentTitle = ""
        var currentNote: String?
        var bodyLines: [String] = []
        var started = false

        func flush() {
            let body = cleanBody(bodyLines)
            if !currentTitle.isEmpty || !body.isEmpty {
                sections.append(makeSection(id: sections.count, title: currentTitle, note: currentNote, body: body))
            }
            bodyLines = []
        }

        for rawLine in raw.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n") {
            let line = sanitize(rawLine)
            if line == nil { continue } // linha de cerca de código ou separador
            let text = line!
            if let header = header(from: text) {
                if started || !bodyLines.isEmpty { flush() }
                currentTitle = header.title
                currentNote = header.note
                started = true
            } else {
                bodyLines.append(text)
            }
        }
        flush()

        if sections.isEmpty {
            sections = [makeSection(id: 0, title: "", note: nil, body: "")]
        }
        return ParsedScript(sections: sections)
    }

    /// Tira as marcas de Markdown. Devolve nil para linhas que não são conteúdo.
    static func sanitize(_ line: String) -> String? {
        var text = line.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("```") { return nil }
        if text == "---" || text == "***" { return nil }
        for prefix in ["> ", "- [ ] ", "- [x] ", "- [X] "] where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
        }
        if text == ">" { text = "" }
        text = text.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "__", with: "")
        return text
    }

    /// Título de seção, se a linha for um.
    static func header(from line: String) -> (title: String, note: String?)? {
        if line.hasPrefix("#") {
            let title = line.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
            return title.isEmpty ? nil : split(header: title)
        }
        guard isUppercaseHeader(line) else { return nil }
        return split(header: line)
    }

    static func isUppercaseHeader(_ line: String) -> Bool {
        let withoutNotes = parenthetical.stringByReplacingMatches(
            in: line, range: NSRange(location: 0, length: (line as NSString).length), withTemplate: ""
        ).trimmingCharacters(in: .whitespaces)
        guard !withoutNotes.isEmpty, withoutNotes.count <= 80 else { return false }
        let letters = withoutNotes.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 3 else { return false }
        let upper = letters.filter { CharacterSet.uppercaseLetters.contains($0) }.count
        return Double(upper) / Double(letters.count) >= 0.85
    }

    /// "FECHO DOIS (envio)" → ("FECHO DOIS", "envio").
    static func split(header: String) -> (title: String, note: String?) {
        let ns = header as NSString
        let matches = parenthetical.matches(in: header, range: NSRange(location: 0, length: ns.length))
        let notes = matches.map { ns.substring(with: $0.range).dropFirst().dropLast() }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let title = parenthetical.stringByReplacingMatches(
            in: header, range: NSRange(location: 0, length: ns.length), withTemplate: ""
        )
        .replacingOccurrences(of: "  ", with: " ")
        .trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ":—-")))
        return (title, notes.isEmpty ? nil : notes.joined(separator: " · "))
    }

    /// Junta as linhas do corpo, tirando linhas vazias das pontas e repetidas no meio.
    static func cleanBody(_ lines: [String]) -> String {
        var result: [String] = []
        for line in lines {
            if line.isEmpty, result.last?.isEmpty ?? true { continue }
            result.append(line)
        }
        while result.last?.isEmpty == true { result.removeLast() }
        return result.joined(separator: "\n")
    }

    static func makeSection(id: Int, title: String, note: String?, body: String) -> ScriptSection {
        let ns = body as NSString
        let full = NSRange(location: 0, length: ns.length)
        let directions = parenthetical.matches(in: body, range: full).map(\.range)
        let tokens = TextNormalizer.wordPattern.matches(in: body, range: full).map { match -> ScriptToken in
            let normalized = TextNormalizer.normalize(ns.substring(with: match.range))
            let inDirection = directions.contains { NSIntersectionRange($0, match.range).length > 0 }
            return ScriptToken(
                range: match.range,
                normalized: normalized,
                isTrackable: !inDirection && !TextNormalizer.isNumber(normalized)
            )
        }
        return ScriptSection(id: id, title: title, note: note, body: body, tokens: tokens, directionRanges: directions)
    }
}

/// Tempo de leitura em voz alta.
public enum ReadingTime {
    /// Ritmo médio de fala em português num vídeo curto.
    public static let defaultWordsPerMinute: Double = 150

    public static func seconds(words: Int, wordsPerMinute: Double = defaultWordsPerMinute) -> Double {
        guard wordsPerMinute > 0 else { return 0 }
        return Double(words) / wordsPerMinute * 60
    }

    /// "45 s", "1 min 10 s".
    public static func label(seconds: Double) -> String {
        let total = Int(seconds.rounded())
        if total < 60 { return "\(total) s" }
        let minutes = total / 60, rest = total % 60
        return rest == 0 ? "\(minutes) min" : "\(minutes) min \(rest) s"
    }
}
