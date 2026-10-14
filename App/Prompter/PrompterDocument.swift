import TeleprompterCore
import UIKit

/// O roteiro já montado para a tela: o texto com estilo, onde fica cada palavra acompanhável
/// (para o modo Voz) e onde começa cada seção (para os atalhos).
struct PrompterDocument {
    struct SectionMark {
        let section: ScriptSection
        /// Início da seção no texto montado (o título, se houver).
        let location: Int
        /// Índice da primeira palavra acompanhável da seção em `trackableRanges`.
        let firstToken: Int
    }

    let text: NSAttributedString
    /// Palavras acompanháveis, em ordem: o lugar no texto montado.
    let trackableRanges: [NSRange]
    /// As mesmas palavras, normalizadas (vão para o VoiceMatcher).
    let trackableWords: [String]
    let sections: [SectionMark]
    let wordCount: Int

    struct Style {
        var fontSize: CGFloat
        var lineSpacing: CGFloat
        var alignment: NSTextAlignment
    }

    static let textColor = UIColor.white
    static let directionColor = UIColor(white: 1, alpha: 0.42)
    static let headerColor = UIColor(white: 1, alpha: 0.38)
    static let readColor = UIColor(white: 1, alpha: 0.3)

    init(script: ParsedScript, style: Style) {
        let result = NSMutableAttributedString()
        var ranges: [NSRange] = []
        var words: [String] = []
        var marks: [SectionMark] = []

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = style.alignment
        paragraph.lineHeightMultiple = style.lineSpacing
        paragraph.paragraphSpacing = style.fontSize * 0.45
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.hyphenationFactor = 0

        let bodyFont = UIFont.systemFont(ofSize: style.fontSize, weight: .semibold)
        let directionFont = UIFont.italicSystemFont(ofSize: style.fontSize * 0.72)
        let headerSize = max(13, style.fontSize * 0.42)
        let headerFont = UIFont.systemFont(ofSize: headerSize, weight: .bold)

        let headerParagraph = NSMutableParagraphStyle()
        headerParagraph.alignment = style.alignment
        headerParagraph.paragraphSpacingBefore = style.fontSize * 0.9
        headerParagraph.paragraphSpacing = style.fontSize * 0.25

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont, .foregroundColor: Self.textColor, .paragraphStyle: paragraph
        ]
        let speaking = script.sections.filter { $0.hasSpeech || !$0.title.isEmpty }

        for (index, section) in speaking.enumerated() {
            let sectionStart = result.length
            let firstToken = ranges.count

            if !section.title.isEmpty, speaking.count > 1 || section.note != nil {
                var header = section.displayTitle.uppercased(with: Locale(identifier: "pt_BR"))
                if let note = section.note { header += "  ·  " + note }
                let paragraphForHeader = index == 0 ? Self.paragraphWithoutSpaceBefore(headerParagraph) : headerParagraph
                result.append(NSAttributedString(string: header + "\n", attributes: [
                    .font: headerFont, .foregroundColor: Self.headerColor,
                    .paragraphStyle: paragraphForHeader, .kern: headerSize * 0.08
                ]))
            }

            let bodyStart = result.length
            let body = NSMutableAttributedString(string: section.body, attributes: bodyAttributes)
            for direction in section.directionRanges {
                body.addAttributes([.font: directionFont, .foregroundColor: Self.directionColor], range: direction)
            }
            result.append(body)
            for token in section.tokens where token.isTrackable {
                ranges.append(NSRange(location: bodyStart + token.range.location, length: token.range.length))
                words.append(token.normalized)
            }
            if index < speaking.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: bodyAttributes))
            }
            marks.append(SectionMark(section: section, location: sectionStart, firstToken: firstToken))
        }

        text = result
        trackableRanges = ranges
        trackableWords = words
        sections = marks
        wordCount = max(1, script.wordCount)
    }

    private static func paragraphWithoutSpaceBefore(_ style: NSParagraphStyle) -> NSParagraphStyle {
        let copy = style.mutableCopy() as! NSMutableParagraphStyle
        copy.paragraphSpacingBefore = 0
        return copy
    }

    /// Índice da seção que contém a posição do texto.
    func sectionIndex(containing location: Int) -> Int {
        var current = 0
        for (index, mark) in sections.enumerated() where mark.location <= location {
            current = index
        }
        return current
    }

    /// Primeira palavra acompanhável a partir da posição do texto.
    func tokenIndex(atOrAfter location: Int) -> Int {
        var low = 0, high = trackableRanges.count
        while low < high {
            let mid = (low + high) / 2
            if NSMaxRange(trackableRanges[mid]) <= location { low = mid + 1 } else { high = mid }
        }
        return low
    }
}
