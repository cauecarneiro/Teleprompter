import SwiftUI
import UIKit

/// Visual: preto, branco e cinzas. A única cor é o vermelho de gravar.
enum Palette {
    static let background = Color.black
    static let surface = Color.white.opacity(0.06)
    static let surfaceStrong = Color.white.opacity(0.1)
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.55)
    static let tertiary = Color.white.opacity(0.32)
    static let hairline = Color.white.opacity(0.1)
    static let record = Color(red: 1.0, green: 0.23, blue: 0.19)
}

extension View {
    /// Vidro do iOS 26 quando houver; material escuro antes disso.
    @ViewBuilder
    func glass(cornerRadius: CGFloat = 22, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .environment(\.colorScheme, .dark)
        }
    }

    @ViewBuilder
    func glassCircle(interactive: Bool = true) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: .circle)
        } else {
            self.background(.ultraThinMaterial, in: Circle()).environment(\.colorScheme, .dark)
        }
    }
}

enum Haptics {
    @MainActor static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    @MainActor static func tick() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7) }
    @MainActor static func heavy() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    @MainActor static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    @MainActor static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

/// "01:07"
func clockLabel(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    return String(format: "%02d:%02d", total / 60, total % 60)
}
