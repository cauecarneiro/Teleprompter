// Gera o ícone do app (1024×1024): fundo preto, três linhas de texto brancas
// (a do meio é a linha de leitura, mais forte) e o ponto vermelho de gravar.
// Uso: swift scripts/gerar-icone.swift App/Resources/Assets.xcassets/AppIcon.appiconset/icone-1024.png
import AppKit
import CoreGraphics

let size = 1024
let output = CommandLine.arguments.dropFirst().first ?? "icone-1024.png"
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(CGColor(srgbRed: 0.04, green: 0.04, blue: 0.04, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

func bar(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ alpha: CGFloat) {
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: alpha))
    let path = CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: h / 2, cornerHeight: h / 2, transform: nil)
    ctx.addPath(path); ctx.fillPath()
}
// Coordenadas do CoreGraphics: y cresce para cima.
bar(232, 640, 420, 64, 0.32)   // linha já lida
bar(232, 480, 560, 84, 1.0)    // linha de leitura
bar(232, 340, 470, 64, 0.32)   // próxima linha
ctx.setFillColor(CGColor(srgbRed: 1, green: 0.23, blue: 0.19, alpha: 1))
ctx.fillEllipse(in: CGRect(x: 690, y: 690, width: 96, height: 96))

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: output))
print("ícone salvo em \(output)")
