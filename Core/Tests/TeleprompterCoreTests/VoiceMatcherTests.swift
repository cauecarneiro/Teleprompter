import Testing
@testable import TeleprompterCore

@Suite("Acompanhamento por voz")
struct VoiceMatcherTests {
    let script = """
    O nome dele é Reverse Engineer Anything. E tem um detalhe que quase ninguém tá contando.
    Você aponta um agente de IA pra um app e pede pra ele entender como uma função funciona.
    Então o que ficou barato foi copiar a função. Copiar cliente, confiança e distribuição, não.
    """

    func matcher() -> VoiceMatcher {
        VoiceMatcher(words: TextNormalizer.words(in: script))
    }

    @Test func andaJuntoComAFala() {
        let m = matcher()
        m.update(transcript: "o nome dele")
        #expect(m.position == 3)
        m.update(transcript: "o nome dele é reverse engineer anything e tem um detalhe")
        #expect(m.position == 11)
    }

    @Test func reconhecimentoErradoNumaPalavraNaoTrava() {
        let m = matcher()
        // "riverse" e "enginir": o reconhecimento em português erra nomes em inglês.
        m.update(transcript: "o nome dele é riverse enginir anything e tem um detalhe que quase")
        #expect(m.position == 13)
    }

    @Test func pularUmaFraseInteira() {
        let m = matcher()
        m.update(transcript: "o nome dele é reverse engineer anything")
        // Pula "E tem um detalhe que quase ninguém tá contando" e vai direto para a frase seguinte.
        m.update(transcript: "você aponta um agente de ia")
        #expect(m.words[m.position - 1] == "ia")
    }

    @Test func voltaQuandoRepeteAFrase() {
        let m = matcher()
        m.update(transcript: "o nome dele é reverse engineer anything e tem um detalhe que quase ninguém tá contando você aponta")
        let adiante = m.position
        // Errou e começou a frase de novo.
        m.update(transcript: "e tem um detalhe que")
        #expect(m.position < adiante)
        #expect(m.words[m.position - 1] == "que")
    }

    @Test func palavraComumSozinhaNaoVolta() {
        let m = matcher()
        m.update(transcript: "o nome dele é reverse engineer anything e tem um detalhe que quase ninguém tá contando")
        let antes = m.position
        m.update(transcript: "um")
        #expect(m.position == antes)
    }

    @Test func improvisoNaoMexe() {
        let m = matcher()
        m.update(transcript: "o nome dele é reverse")
        let antes = m.position
        m.update(transcript: "galera bora lá pessoal hoje")
        #expect(m.position == antes)
    }

    @Test func reiniciarNaPosicao() {
        let m = matcher()
        m.reset(to: 20)
        #expect(m.position == 20)
        m.reset(to: 10_000)
        #expect(m.position == m.words.count)
    }
}
