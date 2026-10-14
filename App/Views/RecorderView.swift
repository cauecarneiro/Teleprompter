import AVKit
import SwiftData
import SwiftUI
import TeleprompterCore

/// A tela de gravar: câmera em tela cheia, o texto no alto (perto da lente), controles embaixo.
struct RecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: RecorderModel
    @State private var showSettings = false
    @State private var focusPoint: CGPoint?
    @State private var focusLocked = false
    @State private var focusID = UUID()
    @FocusState private var keyboardFocus: Bool
    @Bindable private var settings = PrompterSettings.shared

    init(script: Script) {
        _model = State(initialValue: RecorderModel(script: script))
    }

    private var prompter: PrompterController { model.prompter }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                cameraLayer
                if settings.showGuides { FramingGuides() }

                VStack(spacing: 0) {
                    prompterPanel(height: geo.size.height * settings.panelHeight)
                    statusRow
                        .padding(.top, 10)
                    Spacer(minLength: 0)
                    if !model.isRecording, prompter.sections.count > 1 {
                        SectionChips(
                            sections: prompter.sections,
                            current: prompter.currentSection,
                            recorded: model.script.recordedSections,
                            onSelect: { prompter.jump(toSection: $0) }
                        )
                        .padding(.bottom, 14)
                        .transition(.opacity)
                    }
                    controls
                        .padding(.bottom, max(12, geo.safeAreaInsets.bottom > 0 ? 4 : 16))
                }

                if case .countdown(let value) = model.phase {
                    CountdownOverlay(value: value)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
                }

                if let toast = model.toast {
                    VStack {
                        Spacer()
                        ToastView(toast: toast) { model.redoLastSection() }
                            .padding(.bottom, 150)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: model.isRecording)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: model.toast)
        }
        .background(Color.black)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onCameraCaptureEvent(isEnabled: model.cameraReady) { event in
            // Botões de volume e Controle da Câmera: gravar e parar.
            if event.phase == .ended { model.recordTapped() }
        }
        .focusable()
        .focused($keyboardFocus)
        .focusEffectDisabled()
        .onKeyPress(.space) { prompter.toggle(); return .handled }
        .onKeyPress(.return) { model.recordTapped(); return .handled }
        .onKeyPress(.upArrow) { prompter.nudge(lines: -1); return .handled }
        .onKeyPress(.downArrow) { prompter.nudge(lines: 1); return .handled }
        .onKeyPress(.leftArrow) { model.slower(); return .handled }
        .onKeyPress(.rightArrow) { model.faster(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "rR")) { _ in model.recordTapped(); return .handled }
        .onAppear {
            model.start(context: context)
            keyboardFocus = true
        }
        .onDisappear { model.stop() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: model.appDidEnterBackground()
            case .active: model.appDidBecomeActive()
            default: break
            }
        }
        .onChange(of: settings.cameraConfiguration) { _, _ in model.reconfigureCamera() }
        .onChange(of: settings.wordsPerMinute) { _, value in prompter.wordsPerMinute = value }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(model: model)
                .presentationDetents([.medium, .large])
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(28)
        }
    }

    // MARK: Câmera

    @ViewBuilder
    private var cameraLayer: some View {
        ZStack {
            // A prévia só entra depois da permissão: montar antes faz o iOS pedir acesso de novo.
            if model.cameraReady {
                CameraPreview(session: model.camera.session) { devicePoint, viewPoint, lock in
                    model.focus(devicePoint: devicePoint, lock: lock)
                    focusPoint = viewPoint
                    focusLocked = lock
                    focusID = UUID()
                }
                .transition(.opacity.animation(.easeIn(duration: 0.35)))
            } else if model.cameraDenied || !model.cameraExpected {
                cameraPlaceholder
            }
            if let focusPoint {
                FocusIndicator(locked: focusLocked)
                    .id(focusID)
                    .position(focusPoint)
                    .task(id: focusID) {
                        try? await Task.sleep(for: .seconds(focusLocked ? 2.5 : 1.2))
                        withAnimation(.easeOut(duration: 0.2)) { self.focusPoint = nil }
                    }
            }
        }
        .ignoresSafeArea()
    }

    private var cameraPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: model.cameraDenied ? "video.slash" : "camera")
                .font(.system(size: 30, weight: .light))
            Text(model.cameraDenied ? "Sem acesso à câmera.\nAtive em Ajustes > Teleprompter." : "A câmera aparece aqui no iPhone.")
                .font(.footnote)
                .multilineTextAlignment(.center)
            if model.cameraDenied {
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .font(.footnote.weight(.semibold))
                .padding(.top, 4)
            }
        }
        .foregroundStyle(Palette.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 200)
    }

    // MARK: Texto

    private func prompterPanel(height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(settings.panelOpacity))
                .ignoresSafeArea(edges: .top)
            PrompterPanel(
                controller: prompter,
                script: model.parsed,
                scriptKey: model.script.id.uuidString,
                appearance: .init(
                    fontSize: settings.fontSize,
                    lineSpacing: settings.lineSpacing,
                    alignment: settings.alignment.nsAlignment,
                    textWidth: settings.textWidth,
                    mirror: settings.mirrorText,
                    dimReadText: settings.dimReadText
                ),
                onFontSizeChange: { settings.fontSize = $0 }
            )
            GeometryReader { geo in
                Rectangle()
                    .fill(.white.opacity(0.85))
                    .frame(width: geo.size.width * prompter.progress, height: 2)
                    .animation(.linear(duration: 0.15), value: prompter.progress)
            }
            .frame(height: 2)
        }
        .frame(height: height)
    }

    // MARK: Linha de estado

    private var statusRow: some View {
        HStack(spacing: 10) {
            if model.isRecording || model.phase == .saving {
                recordingPill
            }
            Spacer()
            if prompter.mode == .auto {
                speedPill
            } else if prompter.mode == .voice {
                voicePill
            }
        }
        .padding(.horizontal, 16)
    }

    private var recordingPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Palette.record)
                .frame(width: 9, height: 9)
                .opacity(model.phase == .saving ? 0.4 : 1)
            TimelineView(.periodic(from: .now, by: 0.5)) { context in
                let elapsed = model.recordingStartedAt.map { context.date.timeIntervalSince($0) } ?? 0
                Text(model.phase == .saving ? "Salvando" : clockLabel(elapsed))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            AudioMeter(level: model.audioLevel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(.black.opacity(0.55)))
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private var speedPill: some View {
        HStack(spacing: 0) {
            Button { model.slower() } label: {
                Image(systemName: "minus").frame(width: 34, height: 32)
            }
            VStack(spacing: 0) {
                Text("\(Int(prompter.wordsPerMinute))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("ppm · ~\(ReadingTime.label(seconds: model.remainingSeconds))")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Palette.secondary)
            }
            .frame(minWidth: 70)
            Button { model.faster() } label: {
                Image(systemName: "plus").frame(width: 34, height: 32)
            }
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.white)
        .padding(.vertical, 3)
        .background(Capsule().fill(.black.opacity(0.55)))
        .animation(.snappy, value: prompter.wordsPerMinute)
    }

    private var voicePill: some View {
        HStack(spacing: 6) {
            Image(systemName: model.voiceStatus == .listening ? "waveform" : "waveform.slash")
                .symbolEffect(.variableColor.iterative, isActive: model.voiceStatus == .listening && prompter.isPlaying)
            Text(voiceLabel)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.black.opacity(0.55)))
    }

    private var voiceLabel: String {
        switch model.voiceStatus {
        case .listening: prompter.isPlaying ? "Seguindo a voz" : "Toque no texto para seguir"
        case .denied: "Voz sem permissão"
        case .unavailable: "Voz indisponível"
        case .off: "Voz desligada"
        }
    }

    // MARK: Controles

    private var controls: some View {
        HStack {
            CircleIconButton(systemName: "xmark", label: "Fechar") {
                if model.isRecording { model.stopRecording() }
                dismiss()
            }
            .opacity(model.isRecording ? 0 : 1)
            .disabled(model.isRecording)

            Spacer()

            CircleIconButton(systemName: prompter.mode.icon, label: "Modo: \(prompter.mode.label)") {
                model.cycleMode()
            }

            Spacer()

            RecordButton(isRecording: model.isRecording, isCountingDown: {
                if case .countdown = model.phase { return true } else { return false }
            }()) {
                model.recordTapped()
            }
            .disabled(model.phase == .saving)

            Spacer()

            CircleIconButton(
                systemName: prompter.isPlaying ? "pause.fill" : "play.fill",
                label: prompter.isPlaying ? "Pausar texto" : "Rolar texto"
            ) {
                Haptics.tap()
                prompter.toggle()
            }
            .opacity(prompter.mode == .manual ? 0.35 : 1)
            .disabled(prompter.mode == .manual)

            Spacer()

            CircleIconButton(systemName: "slider.horizontal.3", label: "Ajustes") {
                showSettings = true
            }
            .opacity(model.isRecording ? 0 : 1)
            .disabled(model.isRecording)
        }
        .padding(.horizontal, 20)
    }
}
