// swift-tools-version: 6.0
import PackageDescription

// Núcleo sem interface: lê o roteiro colado (seções em CAIXA ALTA, indicações entre parênteses),
// normaliza palavras e acompanha a fala. Roda no Mac com `swift test`, sem simulador.
let package = Package(
    name: "TeleprompterCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "TeleprompterCore", targets: ["TeleprompterCore"])
    ],
    targets: [
        .target(name: "TeleprompterCore"),
        .testTarget(name: "TeleprompterCoreTests", dependencies: ["TeleprompterCore"])
    ],
    swiftLanguageModes: [.v5]
)
