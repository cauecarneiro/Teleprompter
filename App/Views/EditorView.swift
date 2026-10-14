import SwiftData
import SwiftUI
import TeleprompterCore

/// Ver e ajustar o roteiro antes de gravar: seções, tempo por seção e a velocidade para caber no tempo do Reel.
struct EditorView: View {
    @Bindable var script: Script
    let onRecord: () -> Void
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable private var settings = PrompterSettings.shared
    @FocusState private var editing: Bool

    private var parsed: ParsedScript { script.parsed }

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    TextField("Título", text: $script.title, axis: .vertical)
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.4)
                        .foregroundStyle(Palette.primary)

                    overview

                    TextEditor(text: $script.body)
                        .focused($editing)
                        .font(.system(size: 17))
                        .foregroundStyle(Palette.primary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 320)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
                        .overlay(alignment: .topLeading) {
                            if script.body.isEmpty {
                                Text("Cole ou escreva o roteiro aqui.\n\nABERTURA UM\nO texto da abertura…\n\nCORPO\n(olhe para a lente) O texto do corpo…")
                                    .font(.system(size: 17))
                                    .foregroundStyle(Palette.tertiary)
                                    .padding(17)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)

            recordBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if editing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") { editing = false }
                }
            }
        }
        .onChange(of: script.body) { _, _ in touch() }
        .onChange(of: script.title) { _, _ in touch() }
        .onDisappear {
            if script.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, script.takes.isEmpty {
                context.delete(script)
            } else if script.title.trimmingCharacters(in: .whitespaces).isEmpty {
                script.title = parsed.suggestedTitle
            }
            try? context.save()
        }
    }

    private func touch() {
        script.updatedAt = Date()
    }

    // MARK: Resumo

    @ViewBuilder
    private var overview: some View {
        let sections = parsed.speakingSections
        let wpm = settings.wordsPerMinute
        if parsed.wordCount > 0 {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("~" + ReadingTime.label(seconds: ReadingTime.seconds(words: parsed.wordCount, wordsPerMinute: wpm)))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.primary)
                        .contentTransition(.numericText())
                    Text("\(parsed.wordCount) palavras · \(Int(wpm)) ppm")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.secondary)
                    Spacer()
                }
                .animation(.snappy, value: wpm)

                if sections.count > 1 {
                    VStack(spacing: 0) {
                        ForEach(sections) { section in
                            HStack {
                                if script.recordedSections.contains(section.title) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Palette.secondary)
                                }
                                Text(section.displayTitle)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Palette.primary)
                                if let note = section.note {
                                    Text(note)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Palette.tertiary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(ReadingTime.label(seconds: ReadingTime.seconds(words: section.wordCount, wordsPerMinute: wpm)))
                                    .font(.system(size: 14, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.secondary)
                            }
                            .padding(.vertical, 9)
                            if section.id != sections.last?.id {
                                Divider().overlay(Palette.hairline)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surface))
                }

                targetDuration
            }
        }
    }

    /// "Caber em 30 s": calcula a velocidade para o texto todo (sem as aberturas extras) durar isso.
    private var targetDuration: some View {
        HStack(spacing: 8) {
            Text("Caber em")
                .font(.system(size: 13))
                .foregroundStyle(Palette.secondary)
            ForEach([30, 45, 60, 90], id: \.self) { seconds in
                let wpm = requiredWPM(for: Double(seconds))
                let selected = abs(wpm - settings.wordsPerMinute) < 5
                Button {
                    Haptics.tap()
                    settings.wordsPerMinute = wpm
                } label: {
                    Text("\(seconds) s")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .foregroundStyle(selected ? Color.black : Palette.primary)
                        .background(Capsule().fill(selected ? Color.white : Palette.surfaceStrong))
                }
                .buttonStyle(PressableStyle())
                .disabled(wpm >= 260 || wpm <= 80)
                .opacity(wpm >= 260 || wpm <= 80 ? 0.35 : 1)
            }
        }
    }

    /// Para caber no tempo, conta uma abertura só (as outras são versões alternativas).
    private func requiredWPM(for seconds: Double) -> Double {
        let sections = parsed.speakingSections
        let openings = sections.filter { $0.title.uppercased().hasPrefix("ABERTURA") }
        let closings = sections.filter { $0.title.uppercased().hasPrefix("FECHO") }
        var words = parsed.wordCount
        if openings.count > 1 { words -= openings.dropFirst().reduce(0) { $0 + $1.wordCount } }
        if closings.count > 1 { words -= closings.dropFirst().reduce(0) { $0 + $1.wordCount } }
        let raw = Double(max(1, words)) / seconds * 60
        return min(260, max(80, (raw / 5).rounded() * 5))
    }

    // MARK: Gravar

    private var recordBar: some View {
        Button {
            editing = false
            try? context.save()
            onRecord()
        } label: {
            HStack(spacing: 10) {
                Circle().fill(Palette.record).frame(width: 14, height: 14)
                Text("Gravar")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Capsule().fill(.white))
        }
        .buttonStyle(PressableStyle())
        .disabled(parsed.wordCount == 0)
        .opacity(parsed.wordCount == 0 ? 0.4 : 1)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
