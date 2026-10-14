import AVFoundation

/// Microfones disponíveis: o do iPhone, com fio (DJI pelo USB-C ou Lightning) e Bluetooth.
enum AudioInputs {
    struct Input: Identifiable, Hashable {
        let id: String
        let name: String
        let icon: String
    }

    static func configureSession() {
        let audio = AVAudioSession.sharedInstance()
        try? audio.setCategory(.playAndRecord, mode: .videoRecording, options: [.allowBluetoothHFP, .defaultToSpeaker])
        try? audio.setActive(true)
    }

    static var available: [Input] {
        (AVAudioSession.sharedInstance().availableInputs ?? []).map(input(from:))
    }

    static var current: Input? {
        AVAudioSession.sharedInstance().currentRoute.inputs.first.map(input(from:))
    }

    static func select(id: String) {
        let audio = AVAudioSession.sharedInstance()
        let port = audio.availableInputs?.first { $0.uid == id }
        try? audio.setPreferredInput(port)
    }

    private static func input(from port: AVAudioSessionPortDescription) -> Input {
        let icon: String
        switch port.portType {
        case .builtInMic: icon = "iphone"
        case .bluetoothHFP, .bluetoothLE: icon = "headphones"
        case .usbAudio, .headsetMic, .lineIn: icon = "mic.fill"
        default: icon = "mic"
        }
        let name = port.portType == .builtInMic ? "iPhone" : port.portName
        return Input(id: port.uid, name: name, icon: icon)
    }
}
