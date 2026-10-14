import Foundation
import Testing
@testable import TeleprompterCore

/// O bloco "Teleprompter" do Vídeo 20, como ele copia do Notion.
let video20 = """
ORDEM: CORPO (tópicos, fala livre) → PONTE → FRASE-TESE → ABERTURAS (por último) → FECHOS → FRASE-FORTE

CORPO (tópicos — uma ideia por linha, fale com suas palavras)
1. agente de IA entende uma função, mostra a evidência, reconstrói sem ver o código
2. exemplo: um cara controlou a própria TV pelo Mac
3. uma equipe publicou 10+ apps abertos em Rust: Photoshop, Word, Excel
4. MAS: README do PhotoCraft diz "alfa inicial, ainda não substitui o Photoshop" (aponta pra cima, print aqui)

PONTE
O nome dele é Reverse Engineer Anything, REA: engenharia reversa de qualquer coisa. E tem um detalhe que quase ninguém tá contando.

FRASE-TESE (devagar, olhando a lente)
Copiar código ficou barato. Copiar cliente, não.

ABERTURA UM (grave por último)
Esse repositório ganhou 197 mil estrelas em menos de seis meses.

ABERTURA DOIS
Publicaram uma versão aberta do Photoshop. O próprio README diz: ainda não substitui.

FECHO UM (corte seco)
Código virou rascunho. Cliente continua sendo o ativo.
"""

@Suite("Leitura do roteiro")
struct ScriptParserTests {
    @Test func secoesDoBlocoDoNotion() {
        let parsed = ScriptParser.parse(video20)
        #expect(parsed.sections.map(\.title) == [
            "ORDEM: CORPO → PONTE → FRASE-TESE → ABERTURAS → FECHOS → FRASE-FORTE",
            "CORPO", "PONTE", "FRASE-TESE", "ABERTURA UM", "ABERTURA DOIS", "FECHO UM"
        ])
        // A linha de ORDEM não tem fala: não vira atalho.
        #expect(parsed.speakingSections.map(\.displayTitle) == [
            "Corpo", "Ponte", "Frase-tese", "Abertura um", "Abertura dois", "Fecho um"
        ])
    }

    @Test func notaDoTitulo() {
        let parsed = ScriptParser.parse(video20)
        let abertura = parsed.sections.first { $0.title == "ABERTURA UM" }
        #expect(abertura?.note == "grave por último")
        #expect(parsed.sections.first { $0.title == "PONTE" }?.note == nil)
    }

    @Test func indicacaoEntreParentesesNaoEAcompanhada() {
        let parsed = ScriptParser.parse(video20)
        let corpo = parsed.sections.first { $0.title == "CORPO" }!
        #expect(corpo.directionRanges.count == 1)
        let trackable = corpo.tokens.filter(\.isTrackable).map(\.normalized)
        #expect(!trackable.contains("aponta"))
        #expect(!trackable.contains("print"))
        #expect(trackable.contains("photocraft"))
        // Números em algarismos não são acompanhados (a fala diz "cento e noventa e sete").
        #expect(!trackable.contains("10"))
    }

    @Test func textoSemTitulosViraUmaSecao() {
        let parsed = ScriptParser.parse("Oi, tudo bem?\nHoje eu vou falar de startups.")
        #expect(parsed.sections.count == 1)
        #expect(parsed.sections[0].title == "")
        #expect(parsed.sections[0].displayTitle == "Início")
        #expect(parsed.wordCount == 9)
    }

    @Test func fraseGritadaNoMeioNaoViraTitulo() {
        #expect(!ScriptParser.isUppercaseHeader("VOCÊ pode vencer."))
        #expect(!ScriptParser.isUppercaseHeader("MAS: README do PhotoCraft diz"))
        #expect(ScriptParser.isUppercaseHeader("FECHO DOIS (envio)"))
        #expect(ScriptParser.isUppercaseHeader("ABERTURA TRÊS"))
    }

    @Test func marcasDeMarkdownSomem() {
        let parsed = ScriptParser.parse("```text\n## Corpo\n**Olha** isso\n> segunda linha\n```")
        #expect(parsed.sections.map(\.title) == ["Corpo"])
        #expect(parsed.sections[0].body == "Olha isso\nsegunda linha")
    }

    @Test func tituloSugerido() {
        let parsed = ScriptParser.parse(video20)
        #expect(parsed.suggestedTitle == "Agente de IA entende uma função, mostra…")
        #expect(ScriptParser.parse("Curto.").suggestedTitle == "Curto")
        #expect(ScriptParser.parse("").suggestedTitle == "Roteiro")
    }

    @Test func tempoDeLeitura() {
        #expect(ReadingTime.label(seconds: ReadingTime.seconds(words: 150)) == "1 min")
        #expect(ReadingTime.label(seconds: 45) == "45 s")
        #expect(ReadingTime.label(seconds: 75) == "1 min 15 s")
    }
}

@Suite("Palavras")
struct NormalizerTests {
    @Test func acentoECaixa() {
        #expect(TextNormalizer.words(in: "Você, AÇÃO! frase-tese") == ["voce", "acao", "frase", "tese"])
    }

    @Test func quaseIgual() {
        #expect(TextNormalizer.fuzzyEqual("cliente", "clientes"))
        #expect(TextNormalizer.fuzzyEqual("repositorio", "repositorios"))
        #expect(!TextNormalizer.fuzzyEqual("de", "da"))
        #expect(!TextNormalizer.fuzzyEqual("copiar", "colar"))
    }
}
