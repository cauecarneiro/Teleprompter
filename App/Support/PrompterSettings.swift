import Foundation
import Observation
import UIKit

enum ScrollMode: String, CaseIterable, Identifiable {
    case auto, voice, manual
    var id: String { rawValue }
    var label: String {
        switch self {
        case .auto: "Automático"
        case .voice: "Voz"
        case .manual: "Manual"
        }
    }
    var icon: String {
        switch self {
        case .auto: "gauge.with.dots.needle.50percent"
        case .voice: "waveform"
        case .manual: "hand.draw"
        }
    }
    var next: ScrollMode {
        switch self {
        case .auto: .voice
        case .voice: .manual
        case .manual: .auto
        }
    }
}

enum CameraSide: String, CaseIterable, Identifiable {
    case front, back
    var id: String { rawValue }
    var label: String { self == .front ? "Frontal" : "Traseira" }
}

enum BackLens: String, CaseIterable, Identifiable {
    case ultraWide, wide
    var id: String { rawValue }
    var label: String { self == .ultraWide ? "0,5x" : "1x" }
}

enum VideoResolution: String, CaseIterable, Identifiable {
    case uhd4K, fullHD
    var id: String { rawValue }
    var label: String { self == .uhd4K ? "4K" : "1080p" }
}

enum TextAlign: String, CaseIterable, Identifiable {
    case leading, center
    var id: String { rawValue }
    var label: String { self == .leading ? "Esquerda" : "Centro" }
    var nsAlignment: NSTextAlignment { self == .leading ? .natural : .center }
}

struct CameraConfiguration: Equatable, Sendable {
    var side: CameraSide
    var backLens: BackLens
    var resolution: VideoResolution
    var fps: Int
    var stabilization: Bool
    var mirrorRecording: Bool
}

/// Preferências, guardadas no aparelho. Os padrões seguem a cola de gravação:
/// vertical, 4K, 30 fps, HDR desligado, sem filtro.
@Observable
final class PrompterSettings {
    static let shared = PrompterSettings()

    // Texto
    var fontSize: Double = 34 { didSet { save(fontSize, "fontSize") } }
    var lineSpacing: Double = 1.25 { didSet { save(lineSpacing, "lineSpacing") } }
    var textWidth: Double = 0.9 { didSet { save(textWidth, "textWidth") } }
    var alignment: TextAlign = .leading { didSet { save(alignment.rawValue, "alignment") } }
    var mirrorText = false { didSet { save(mirrorText, "mirrorText") } }
    var panelHeight: Double = 0.42 { didSet { save(panelHeight, "panelHeight") } }
    var panelOpacity: Double = 0.5 { didSet { save(panelOpacity, "panelOpacity") } }
    var dimReadText = true { didSet { save(dimReadText, "dimReadText") } }

    // Rolagem
    var scrollMode: ScrollMode = .auto { didSet { save(scrollMode.rawValue, "scrollMode") } }
    var wordsPerMinute: Double = 150 { didSet { save(wordsPerMinute, "wordsPerMinute") } }
    var countdown: Int = 3 { didSet { save(countdown, "countdown") } }
    var scrollStartsWithRecording = true { didSet { save(scrollStartsWithRecording, "scrollStartsWithRecording") } }

    // Câmera
    var cameraSide: CameraSide = .front { didSet { save(cameraSide.rawValue, "cameraSide") } }
    var backLens: BackLens = .ultraWide { didSet { save(backLens.rawValue, "backLens") } }
    var resolution: VideoResolution = .uhd4K { didSet { save(resolution.rawValue, "resolution") } }
    var fps: Int = 30 { didSet { save(fps, "fps") } }
    var stabilization = true { didSet { save(stabilization, "stabilization") } }
    var mirrorRecording = false { didSet { save(mirrorRecording, "mirrorRecording") } }
    var showGuides = false { didSet { save(showGuides, "showGuides") } }

    // Gravação
    var saveToAlbum = true { didSet { save(saveToAlbum, "saveToAlbum") } }

    static let albumName = "Teleprompter"

    var cameraConfiguration: CameraConfiguration {
        CameraConfiguration(
            side: cameraSide, backLens: backLens, resolution: resolution,
            fps: fps, stabilization: stabilization, mirrorRecording: mirrorRecording
        )
    }

    private let defaults: UserDefaults
    private var loading = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loading = true
        defer { loading = false }
        let d = defaults
        if let v = d.object(forKey: "fontSize") as? Double { fontSize = v }
        if let v = d.object(forKey: "lineSpacing") as? Double { lineSpacing = v }
        if let v = d.object(forKey: "textWidth") as? Double { textWidth = v }
        if let v = d.string(forKey: "alignment").flatMap(TextAlign.init) { alignment = v }
        if let v = d.object(forKey: "mirrorText") as? Bool { mirrorText = v }
        if let v = d.object(forKey: "panelHeight") as? Double { panelHeight = v }
        if let v = d.object(forKey: "panelOpacity") as? Double { panelOpacity = v }
        if let v = d.object(forKey: "dimReadText") as? Bool { dimReadText = v }
        if let v = d.string(forKey: "scrollMode").flatMap(ScrollMode.init) { scrollMode = v }
        if let v = d.object(forKey: "wordsPerMinute") as? Double { wordsPerMinute = v }
        if let v = d.object(forKey: "countdown") as? Int { countdown = v }
        if let v = d.object(forKey: "scrollStartsWithRecording") as? Bool { scrollStartsWithRecording = v }
        if let v = d.string(forKey: "cameraSide").flatMap(CameraSide.init) { cameraSide = v }
        if let v = d.string(forKey: "backLens").flatMap(BackLens.init) { backLens = v }
        if let v = d.string(forKey: "resolution").flatMap(VideoResolution.init) { resolution = v }
        if let v = d.object(forKey: "fps") as? Int { fps = v }
        if let v = d.object(forKey: "stabilization") as? Bool { stabilization = v }
        if let v = d.object(forKey: "mirrorRecording") as? Bool { mirrorRecording = v }
        if let v = d.object(forKey: "showGuides") as? Bool { showGuides = v }
        if let v = d.object(forKey: "saveToAlbum") as? Bool { saveToAlbum = v }
    }

    private func save(_ value: Any, _ key: String) {
        guard !loading else { return }
        defaults.set(value, forKey: key)
    }

    func resetText() {
        fontSize = 34; lineSpacing = 1.25; textWidth = 0.9; alignment = .leading
        mirrorText = false; panelHeight = 0.42; panelOpacity = 0.5; dimReadText = true
    }
}
