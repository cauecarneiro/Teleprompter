import SwiftUI
import TeleprompterCore

/// Botão de gravar: anel branco, miolo vermelho que vira quadrado gravando.
struct RecordButton: View {
    let isRecording: Bool
    let isCountingDown: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(.white, lineWidth: 4)
                    .frame(width: 78, height: 78)
                RoundedRectangle(cornerRadius: isRecording ? 8 : 31, style: .continuous)
                    .fill(Palette.record)
                    .frame(width: isRecording ? 30 : 62, height: isRecording ? 30 : 62)
                    .opacity(isCountingDown ? 0.5 : 1)
            }
            .contentShape(Circle())
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isRecording)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(isRecording ? "Parar gravação" : "Gravar")
    }
}

/// Encolhe um pouco ao tocar.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Botão redondo pequeno da barra de controles.
struct CircleIconButton: View {
    let systemName: String
    var label: String = ""
    var size: CGFloat = 48
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .contentShape(Circle())
                .glassCircle()
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }
}

/// As seções do roteiro como atalhos, com ✓ nas que já têm take.
struct SectionChips: View {
    let sections: [ScriptSection]
    let current: Int
    let recorded: Set<String>
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                        Button {
                            Haptics.tap()
                            onSelect(index)
                        } label: {
                            HStack(spacing: 5) {
                                if recorded.contains(section.title) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                Text(section.displayTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .foregroundStyle(index == current ? Color.black : Palette.primary)
                            .background(
                                Capsule().fill(index == current ? Color.white : Color.white.opacity(0.12))
                            )
                        }
                        .buttonStyle(PressableStyle())
                        .id(index)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: current) { _, value in
                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(value, anchor: .center) }
            }
        }
        .animation(.easeOut(duration: 0.2), value: current)
    }
}

/// 3, 2, 1 grande no meio da tela.
struct CountdownOverlay: View {
    let value: Int

    var body: some View {
        Text("\(value)")
            .font(.system(size: 120, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 20)
            .id(value)
            .transition(.asymmetric(insertion: .scale(scale: 1.4).combined(with: .opacity), removal: .opacity))
            .allowsHitTesting(false)
    }
}

/// Terços e a zona segura do Reels (texto entre 270 e 1250 px de 1920; 85 px livres à direita).
struct FramingGuides: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { path in
                for i in 1...2 {
                    let x = w * CGFloat(i) / 3
                    path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: h))
                    let y = h * CGFloat(i) / 3
                    path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: w, y: y))
                }
            }
            .stroke(.white.opacity(0.22), lineWidth: 0.5)

            let top = h * 270 / 1920, bottom = h * 1250 / 1920, right = w * 85 / 1080
            Rectangle()
                .strokeBorder(.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .frame(width: w - right - 1, height: bottom - top)
                .position(x: (w - right) / 2, y: (top + bottom) / 2)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// Barrinha do nível do microfone.
struct AudioMeter: View {
    let level: Float

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                let threshold = Float(i) / 5
                Capsule()
                    .fill(level > threshold ? (i == 4 ? Palette.record : Color.white) : Color.white.opacity(0.25))
                    .frame(width: 3, height: 6 + CGFloat(i) * 2.5)
            }
        }
        .animation(.easeOut(duration: 0.08), value: level)
        .accessibilityHidden(true)
    }
}

struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let text: String
    var icon: String = "checkmark.circle.fill"
    var actionTitle: String?
    var isWarning = false
}

struct ToastView: View {
    let toast: ToastMessage
    var onAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.icon)
                .foregroundStyle(toast.isWarning ? Palette.record : .white)
            Text(toast.text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
            if let title = toast.actionTitle {
                Button(title, action: onAction)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.leading, 4)
                    .underline()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glass(cornerRadius: 18)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// O quadradinho que aparece onde ele tocou para focar.
struct FocusIndicator: View {
    let locked: Bool
    @State private var shrink = false

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.white, lineWidth: 1.5)
                .frame(width: 70, height: 70)
                .scaleEffect(shrink ? 1 : 1.35)
            if locked {
                Text("AE/AF TRAVADO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(.white))
            }
        }
        .onAppear { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { shrink = true } }
        .allowsHitTesting(false)
    }
}
