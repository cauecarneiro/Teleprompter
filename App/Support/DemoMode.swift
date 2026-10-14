#if DEBUG
import Foundation

/// Só na versão de teste: `-demo` cria um roteiro de exemplo, `-demoRecorder` abre a gravação,
/// `-demoPlay` já começa a rolar. Serve para capturar as telas no simulador sem tocar na tela.
enum DemoMode {
    static var arguments: [String] { ProcessInfo.processInfo.arguments }
    static var isOn: Bool { arguments.contains("-demo") }
    static var opensRecorder: Bool { arguments.contains("-demoRecorder") }
    static var plays: Bool { arguments.contains("-demoPlay") }
    static var opensEditor: Bool { arguments.contains("-demoEditor") }

    static let script = """
    CORPO (grave primeiro)
    Existe um jeito de entender qualquer produto de tecnologia sem pedir permissão para ninguém.
    (olhe para a lente)
    Você pega o aplicativo pronto, abre por dentro e lê o que ele faz de verdade.
    Não é mágica, é método: observar, separar o que é fato do que é palpite, e anotar o que falta.

    ABERTURA UM
    Eu desmontei um aplicativo inteiro em uma noite.

    ABERTURA DOIS
    Todo app que você usa tem um manual escondido dentro dele.

    FECHO UM (envio)
    Manda isso para aquele amigo que vive dizendo que quer aprender a programar.
    """
}
#endif
