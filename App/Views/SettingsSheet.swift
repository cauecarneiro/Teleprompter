import SwiftUI

/// Ajustes da gravação. Tudo muda na hora e fica guardado para o próximo take.
struct SettingsSheet: View {
    let model: RecorderModel
    @Bindable private var settings = PrompterSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var inputs: [AudioInputs.Input] = []
    @State private var currentInput: AudioInputs.Input?

    var body: some View {
        NavigationStack {
            Form {
                Section("Texto") {
                    slider("Tamanho", value: $settings.fontSize, in: 18...72, step: 1) { "\(Int($0))" }
                    slider("Entrelinha", value: $settings.lineSpacing, in: 1.0...1.8, step: 0.05) { String(format: "%.2f", $0) }
                    slider("Largura", value: $settings.textWidth, in: 0.6...1.0, step: 0.02) { "\(Int($0 * 100))%" }
                    slider("Altura do painel", value: $settings.panelHeight, in: 0.25...0.7, step: 0.01) { "\(Int($0 * 100))%" }
                    slider("Fundo do painel", value: $settings.panelOpacity, in: 0...1, step: 0.05) { "\(Int($0 * 100))%" }
                    Picker("Alinhamento", selection: $settings.alignment) {
                        ForEach(TextAlign.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("Apagar o que já foi lido", isOn: $settings.dimReadText)
                    Toggle("Espelhar o texto", isOn: $settings.mirrorText)
                    Button("Restaurar o texto") { settings.resetText() }
                        .foregroundStyle(Palette.secondary)
                }

                Section {
                    Picker("Modo", selection: Binding(get: { model.prompter.mode }, set: { model.setMode($0) })) {
                        ForEach(ScrollMode.allCases) { Label($0.label, systemImage: $0.icon).tag($0) }
                    }
                    Stepper(value: $settings.wordsPerMinute, in: 80...260, step: 10) {
                        LabeledContent("Velocidade", value: "\(Int(settings.wordsPerMinute)) ppm")
                    }
                    Picker("Contagem antes de gravar", selection: $settings.countdown) {
                        Text("Sem").tag(0)
                        Text("3 s").tag(3)
                        Text("5 s").tag(5)
                        Text("10 s").tag(10)
                    }
                    Toggle("Rolar quando começar a gravar", isOn: $settings.scrollStartsWithRecording)
                } header: {
                    Text("Rolagem")
                } footer: {
                    Text("Voz: o texto anda quando você fala e para quando você improvisa. Roda no próprio iPhone quando o português está baixado; senão, usa o reconhecimento da Apple pela internet. Para o corpo em tópicos, prefira o Automático.")
                }

                Section {
                    Picker("Câmera", selection: $settings.cameraSide) {
                        ForEach(CameraSide.allCases) { Text($0.label).tag($0) }
                    }
                    if settings.cameraSide == .back {
                        Picker("Lente", selection: $settings.backLens) {
                            ForEach(BackLens.allCases) { Text($0.label).tag($0) }
                        }
                    }
                    Picker("Resolução", selection: $settings.resolution) {
                        ForEach(VideoResolution.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Quadros por segundo", selection: $settings.fps) {
                        Text("24").tag(24)
                        Text("30").tag(30)
                        Text("60").tag(60)
                    }
                    Toggle("Estabilização", isOn: $settings.stabilization)
                    Toggle("Grade e zona segura do Reels", isOn: $settings.showGuides)
                } header: {
                    Text("Câmera")
                } footer: {
                    Text("Vertical, HDR desligado, sem filtro. Toque na imagem para focar; segure para travar foco e exposição.")
                }

                Section {
                    if inputs.isEmpty {
                        LabeledContent("Microfone", value: currentInput?.name ?? "iPhone")
                    } else {
                        Picker("Microfone", selection: Binding(
                            get: { currentInput?.id ?? "" },
                            set: { id in
                                AudioInputs.select(id: id)
                                refreshInputs()
                            }
                        )) {
                            ForEach(inputs) { Label($0.name, systemImage: $0.icon).tag($0.id) }
                        }
                    }
                    Toggle("Guardar no álbum Teleprompter", isOn: $settings.saveToAlbum)
                } header: {
                    Text("Áudio e galeria")
                } footer: {
                    Text("Cada take vai direto para a galeria, no arquivo original, sem recompressão. Ligue o microfone antes de abrir esta tela.")
                }

                Section {
                    Text("Sem conta, sem internet e sem nuvem. O roteiro fica só neste iPhone.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .onAppear(perform: refreshInputs)
        }
        .preferredColorScheme(.dark)
    }

    private func refreshInputs() {
        inputs = AudioInputs.available
        currentInput = AudioInputs.current
    }

    private func slider(
        _ title: String, value: Binding<Double>, in range: ClosedRange<Double>, step: Double,
        label: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(label(value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(Palette.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }
}
