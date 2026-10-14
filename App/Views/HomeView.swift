import SwiftData
import SwiftUI
import TeleprompterCore

/// A tela de entrada: colar e gravar. A lista de roteiros aparece embaixo, quando houver.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var recording: Script?
    @State private var path: [Script] = []
    @State private var settings = PrompterSettings.shared
    @State private var hasCopiedText = false
    @State private var pasteHint: String?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Palette.background.ignoresSafeArea()
                if scripts.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationDestination(for: Script.self) { script in
                EditorView(script: script) { recording = script }
            }
            .toolbar {
                if !scripts.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            let script = Script(title: "", body: "")
                            context.insert(script)
                            path.append(script)
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .accessibilityLabel("Escrever roteiro")
                    }
                }
            }
            .navigationTitle(scripts.isEmpty ? "" : "Roteiros")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(item: $recording) { script in
            RecorderView(script: script)
        }
        #if DEBUG
        .task {
            guard DemoMode.isOn, scripts.isEmpty else { return }
            let parsed = ScriptParser.parse(DemoMode.script)
            let script = Script(title: parsed.suggestedTitle, body: DemoMode.script)
            context.insert(script)
            try? context.save()
            if DemoMode.opensRecorder { recording = script }
            if DemoMode.opensEditor { path.append(script) }
        }
        #endif
    }

    // MARK: Vazio

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Palette.secondary)
                Text("Cole o roteiro.\nAperte gravar.")
                    .font(.system(size: 40, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(Palette.primary)
                Text("As linhas em CAIXA ALTA viram seções, e o que estiver entre parênteses fica em cinza, fora da leitura.")
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            Spacer()
            Spacer()
            if let pasteHint {
                Text(pasteHint)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondary)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }
            pasteButton
                .padding(.horizontal, 24)
            Button {
                let script = Script(title: "", body: "")
                context.insert(script)
                path.append(script)
            } label: {
                Text("Escrever")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.top, 6)
            .padding(.bottom, 18)
        }
    }

    /// Colar e gravar: lê o texto copiado e abre a gravação.
    /// O iOS pergunta "Permitir colar?" até ele escolher Permitir em Ajustes > Teleprompter > Colar de Outros Apps.
    private var pasteButton: some View {
        Button {
            guard let text = UIPasteboard.general.string,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                Haptics.error()
                pasteHint = "Não achei texto copiado. Copie o roteiro no Notion e toque de novo."
                return
            }
            pasteHint = nil
            createAndRecord(text)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 17, weight: .semibold))
                Text("Colar e gravar")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Capsule().fill(.white))
            .opacity(hasCopiedText ? 1 : 0.55)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Colar o roteiro e gravar")
        .onAppear { hasCopiedText = UIPasteboard.general.hasStrings }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            hasCopiedText = UIPasteboard.general.hasStrings
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            hasCopiedText = UIPasteboard.general.hasStrings
        }
    }

    private func createAndRecord(_ text: String) {
        let parsed = ScriptParser.parse(text)
        let script = Script(title: parsed.suggestedTitle, body: text)
        context.insert(script)
        try? context.save()
        Haptics.success()
        recording = script
    }

    // MARK: Lista

    private var list: some View {
        List {
            Section {
                pasteButton
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                if let pasteHint {
                    Text(pasteHint)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondary)
                        .listRowBackground(Color.clear)
                }
            }
            Section {
                ForEach(scripts) { script in
                    ScriptRow(script: script, wordsPerMinute: settings.wordsPerMinute) {
                        recording = script
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { path.append(script) }
                    .listRowBackground(Palette.surface)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(script) } label: {
                            Label("Apagar", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button { recording = script } label: { Label("Gravar", systemImage: "record.circle") }
                        Button { path.append(script) } label: { Label("Editar", systemImage: "pencil") }
                        Button { duplicate(script) } label: { Label("Duplicar", systemImage: "plus.square.on.square") }
                        Button(role: .destructive) { delete(script) } label: { Label("Apagar", systemImage: "trash") }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .animation(.default, value: scripts.count)
    }

    private func delete(_ script: Script) {
        withAnimation { context.delete(script) }
        try? context.save()
    }

    private func duplicate(_ script: Script) {
        let copy = Script(title: script.title + " (cópia)", body: script.body)
        context.insert(copy)
        try? context.save()
    }
}

private struct ScriptRow: View {
    let script: Script
    let wordsPerMinute: Double
    let onRecord: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(script.title.isEmpty ? "Sem título" : script.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.primary)
                    .lineLimit(2)
                Text(script.summary(wordsPerMinute: wordsPerMinute))
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.secondary)
                Text(script.updatedAt, format: .relative(presentation: .named))
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.tertiary)
            }
            Spacer(minLength: 8)
            Button(action: onRecord) {
                ZStack {
                    Circle().strokeBorder(.white.opacity(0.9), lineWidth: 2).frame(width: 36, height: 36)
                    Circle().fill(Palette.record).frame(width: 26, height: 26)
                }
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Gravar \(script.title)")
        }
        .padding(.vertical, 6)
    }
}
