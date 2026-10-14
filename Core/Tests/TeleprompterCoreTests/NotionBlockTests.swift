import XCTest
@testable import TeleprompterCore

/// O bloco "Teleprompter" do Vídeo 20, como sai do Notion (14/10/2026).
final class NotionBlockTests: XCTestCase {
    let block = """
    ORDEM: CORPO (tópicos, fala livre) → PONTE → FRASE-TESE → ABERTURAS (por último) → FECHOS → FRASE-FORTE

    CORPO (tópicos — uma ideia por linha, fale com suas palavras)
    1. agente de IA entende uma função, mostra a evidência, reconstrói sem ver o código
    2. exemplo: um cara controlou a própria TV pelo Mac
    3. uma equipe publicou 10+ apps abertos em Rust: Photoshop, Word, Excel
    4. MAS: README do PhotoCraft diz "alfa inicial, ainda não substitui o Photoshop" (aponta pra cima, print aqui)
    5. o próprio REA avisa: não ajuda a burlar licença nem copiar software proprietário
    6. o que ficou barato: a função. o que não: cliente, confiança, distribuição
    7. a pergunta mudou: não é "copiam igual?", é "quem já confia em mim?"

    PONTE
    O nome dele é Reverse Engineer Anything, REA: engenharia reversa de qualquer coisa. E tem um detalhe que quase ninguém tá contando.

    FRASE-TESE (devagar, olhando a lente)
    Copiar código ficou barato. Copiar cliente, não.

    ABERTURA UM (grave por último)
    Esse repositório ganhou 197 mil estrelas em menos de seis meses.

    ABERTURA DOIS
    Publicaram uma versão aberta do Photoshop. O próprio README diz: ainda não substitui.

    ABERTURA TRÊS
    Sua startup é só código? Esse repositório tem 197 mil estrelas.

    FECHO UM (corte seco)
    Código virou rascunho. Cliente continua sendo o ativo.

    FECHO DOIS (envio)
    Manda pro seu sócio que ainda acha que o código é o segredo.

    FRASE-FORTE (duas vezes, sozinha: uma falando, outra quase sussurrando)
    Copiar código ficou barato. Copiar cliente, não.
    """

    func testSectionsOfVideo20() {
        let parsed = ScriptParser.parse(block)
        let titles = parsed.speakingSections.map(\.title)
        XCTAssertEqual(titles, [
            "CORPO", "PONTE", "FRASE-TESE", "ABERTURA UM", "ABERTURA DOIS", "ABERTURA TRÊS",
            "FECHO UM", "FECHO DOIS", "FRASE-FORTE"
        ])
        XCTAssertEqual(parsed.speakingSections[0].note, "tópicos — uma ideia por linha, fale com suas palavras")
        XCTAssertEqual(parsed.speakingSections[3].note, "grave por último")
        XCTAssertEqual(parsed.speakingSections[3].displayTitle, "Abertura um")
        // A linha de ORDEM vira título sem fala: aparece em cinza, mas não vira atalho.
        XCTAssertTrue(parsed.sections[0].title.hasPrefix("ORDEM"))
        XCTAssertFalse(parsed.sections[0].hasSpeech)
        // A indicação do tópico 4 fica fora da voz.
        let corpo = parsed.speakingSections[0]
        XCTAssertTrue(corpo.directionRanges.contains { (corpo.body as NSString).substring(with: $0).contains("aponta") })
        XCTAssertFalse(corpo.tokens.filter(\.isTrackable).map(\.normalized).contains("aponta"))
    }
}
