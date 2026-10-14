import Foundation
import SwiftData
import TeleprompterCore

/// Um roteiro colado. O texto fica como veio; as seções são lidas na hora (`parsed`).
@Model
final class Script {
    var id: UUID = UUID()
    var title: String = ""
    var body: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Take.script)
    var takes: [Take] = []

    init(title: String, body: String) {
        self.title = title
        self.body = body
    }

    var parsed: ParsedScript { ScriptParser.parse(body) }

    /// "6 seções · 1 min 10 s · 3 takes"
    func summary(wordsPerMinute: Double) -> String {
        let parsed = parsed
        var parts: [String] = []
        let sections = parsed.speakingSections.count
        if sections > 1 { parts.append("\(sections) seções") }
        let seconds = ReadingTime.seconds(words: parsed.wordCount, wordsPerMinute: wordsPerMinute)
        parts.append("~" + ReadingTime.label(seconds: seconds))
        if !takes.isEmpty { parts.append(takes.count == 1 ? "1 take" : "\(takes.count) takes") }
        return parts.joined(separator: " · ")
    }

    /// Títulos das seções que já têm pelo menos um take.
    var recordedSections: Set<String> { Set(takes.map(\.sectionTitle)) }
}

/// Um vídeo gravado e salvo na galeria.
@Model
final class Take {
    var id: UUID = UUID()
    /// O título da seção em que a gravação começou ("ABERTURA UM"); vazio se não havia seção.
    var sectionTitle: String = ""
    var duration: Double = 0
    var createdAt: Date = Date()
    /// Identificador do vídeo na galeria (PHAsset), quando o iOS devolve.
    var assetIdentifier: String?
    var script: Script?

    init(sectionTitle: String, duration: Double, assetIdentifier: String?) {
        self.sectionTitle = sectionTitle
        self.duration = duration
        self.assetIdentifier = assetIdentifier
    }
}
