import AVFoundation
import UIKit

struct RecordedTake: Sendable {
    let url: URL
    let duration: TimeInterval
}

enum CameraError: LocalizedError {
    case nothingRecorded, writeFailed, unavailable
    var errorDescription: String? {
        switch self {
        case .nothingRecorded: "Nada foi gravado."
        case .writeFailed: "Não consegui terminar o arquivo do vídeo."
        case .unavailable: "Câmera indisponível."
        }
    }
}

/// Câmera e microfone numa sessão só, gravando com AVAssetWriter.
///
/// Por que AVAssetWriter e não AVCaptureMovieFileOutput: o mesmo áudio que vai para o arquivo
/// alimenta o reconhecimento de voz (modo Voz) e o medidor de nível, sem abrir o microfone duas vezes.
///
/// Filas: `sessionQueue` configura e liga a sessão; `dataQueue` recebe os quadros e escreve o arquivo.
/// Os avisos para a interface chegam sempre no MainActor.
final class CameraController: NSObject, @unchecked Sendable {
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "teleprompter.camera.session")
    private let dataQueue = DispatchQueue(label: "teleprompter.camera.data", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var device: AVCaptureDevice?
    private var fps: Int32 = 30

    // Estado da gravação (só no dataQueue).
    private var writer: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var wantsRecording = false
    private var writerStarted = false
    private var startTime = CMTime.invalid
    private var lastVideoTime = CMTime.invalid
    private var lastLevelReport = CFAbsoluteTimeGetCurrent()

    /// Cada pedaço de áudio do microfone, no `dataQueue` (vai para o reconhecimento de voz).
    var onAudioSample: ((CMSampleBuffer) -> Void)?
    /// Nível do microfone de 0 a 1, umas 12 vezes por segundo.
    var onAudioLevel: (@MainActor (Float) -> Void)?
    /// O primeiro quadro entrou no arquivo: a gravação começou de fato.
    var onRecordingStarted: (@MainActor () -> Void)?
    /// A sessão foi interrompida (ligação, outro app usando a câmera).
    var onInterrupted: (@MainActor () -> Void)?

    static var isAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    override init() {
        super.init()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(sessionInterrupted), name: AVCaptureSession.wasInterruptedNotification, object: session)
        center.addObserver(self, selector: #selector(sessionRuntimeError), name: AVCaptureSession.runtimeErrorNotification, object: session)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Sessão

    /// Aplica a configuração e liga a sessão. Devolve no MainActor se deu certo.
    func configure(_ configuration: CameraConfiguration, completion: @escaping @MainActor (Bool) -> Void) {
        sessionQueue.async { [self] in
            let ok = apply(configuration)
            if ok, !session.isRunning { session.startRunning() }
            Task { @MainActor in completion(ok) }
        }
    }

    func startSession() {
        sessionQueue.async { [self] in
            if !session.isRunning, !session.inputs.isEmpty { session.startRunning() }
        }
    }

    func stopSession() {
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func apply(_ c: CameraConfiguration) -> Bool {
        guard let newDevice = Self.device(for: c) else { return false }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .inputPriority
        // A sessão de áudio é nossa: assim o microfone externo (USB-C, Lightning, Bluetooth) entra.
        session.automaticallyConfiguresApplicationAudioSession = false
        AudioInputs.configureSession()

        if videoInput?.device != newDevice {
            if let old = videoInput { session.removeInput(old) }
            guard let input = try? AVCaptureDeviceInput(device: newDevice), session.canAddInput(input) else { return false }
            session.addInput(input)
            videoInput = input
        }
        device = newDevice

        if audioInput == nil, let mic = AVCaptureDevice.default(for: .audio),
           let input = try? AVCaptureDeviceInput(device: mic), session.canAddInput(input) {
            session.addInput(input)
            audioInput = input
        }

        if !session.outputs.contains(videoOutput) {
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: dataQueue)
            if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        }
        if !session.outputs.contains(audioOutput) {
            audioOutput.setSampleBufferDelegate(self, queue: dataQueue)
            if session.canAddOutput(audioOutput) { session.addOutput(audioOutput) }
        }

        applyFormat(to: newDevice, c)

        if let connection = videoOutput.connection(with: .video) {
            // Quadros já em pé (vertical): o arquivo sai 2160×3840 ou 1080×1920.
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = c.side == .front && c.mirrorRecording
            }
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = c.stabilization ? .standard : .off
            }
        }
        return true
    }

    private static func device(for c: CameraConfiguration) -> AVCaptureDevice? {
        switch c.side {
        case .front:
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        case .back:
            if c.backLens == .ultraWide,
               let ultra = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
                return ultra
            }
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
    }

    /// Escolhe o formato 4K (ou 1080p) de 8 bits que aguenta o fps pedido, com HDR desligado.
    private func applyFormat(to device: AVCaptureDevice, _ c: CameraConfiguration) {
        let wanted: (Int32, Int32) = c.resolution == .uhd4K ? (3840, 2160) : (1920, 1080)
        let rate = Double(c.fps)

        func is8Bit(_ f: AVCaptureDevice.Format) -> Bool {
            let sub = CMFormatDescriptionGetMediaSubType(f.formatDescription)
            return sub == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange || sub == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        }
        func supports(_ f: AVCaptureDevice.Format, _ r: Double) -> Bool {
            f.videoSupportedFrameRateRanges.contains { $0.minFrameRate <= r && $0.maxFrameRate >= r }
        }
        func dims(_ f: AVCaptureDevice.Format) -> CMVideoDimensions {
            CMVideoFormatDescriptionGetDimensions(f.formatDescription)
        }

        let exact = device.formats.filter {
            let d = dims($0)
            return d.width == wanted.0 && d.height == wanted.1 && is8Bit($0) && supports($0, rate)
        }
        var chosen = exact.first(where: { !$0.isVideoBinned }) ?? exact.first
        var chosenRate = rate
        if chosen == nil {
            // Sem 4K nesse fps: a maior resolução de 8 bits que aguenta o fps (ou 30).
            let fallbackRate = supportsAny(device.formats, rate) ? rate : 30
            chosen = device.formats
                .filter { is8Bit($0) && supports($0, fallbackRate) && dims($0).width <= wanted.0 }
                .max { dims($0).width * dims($0).height < dims($1).width * dims($1).height }
            chosenRate = fallbackRate
        }
        guard let format = chosen, (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }
        device.activeFormat = format
        let duration = CMTime(value: 1, timescale: CMTimeScale(chosenRate))
        device.activeVideoMinFrameDuration = duration
        device.activeVideoMaxFrameDuration = duration
        fps = Int32(chosenRate)
        if format.isVideoHDRSupported {
            device.automaticallyAdjustsVideoHDREnabled = false
            device.isVideoHDREnabled = false
        }
        if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
        if device.isSmoothAutoFocusSupported { device.isSmoothAutoFocusEnabled = true }
        if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }

        func supportsAny(_ formats: [AVCaptureDevice.Format], _ r: Double) -> Bool {
            formats.contains { is8Bit($0) && supports($0, r) }
        }
    }

    // MARK: Foco e exposição

    /// Foca e mede a luz no ponto (coordenadas da câmera, 0 a 1). `lock` trava foco e exposição ali.
    func focus(at point: CGPoint, lock: Bool) {
        sessionQueue.async { [self] in
            guard let device, (try? device.lockForConfiguration()) != nil else { return }
            defer { device.unlockForConfiguration() }
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                let mode: AVCaptureDevice.FocusMode = lock ? .autoFocus : .continuousAutoFocus
                if device.isFocusModeSupported(mode) { device.focusMode = mode }
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                let mode: AVCaptureDevice.ExposureMode = lock ? .autoExpose : .continuousAutoExposure
                if device.isExposureModeSupported(mode) { device.exposureMode = mode }
            }
        }
    }

    /// Volta foco e exposição para o automático contínuo, no centro.
    func unlockFocus() {
        focus(at: CGPoint(x: 0.5, y: 0.5), lock: false)
    }

    // MARK: Gravação

    func startRecording() {
        dataQueue.async { [self] in
            writer = nil
            videoWriterInput = nil
            audioWriterInput = nil
            writerStarted = false
            startTime = .invalid
            lastVideoTime = .invalid
            wantsRecording = true
        }
    }

    /// Para e fecha o arquivo. Devolve no MainActor.
    func stopRecording(completion: @escaping @MainActor (Result<RecordedTake, Error>) -> Void) {
        dataQueue.async { [self] in
            wantsRecording = false
            guard let writer, writerStarted, lastVideoTime.isValid else {
                self.writer?.cancelWriting()
                resetWriter()
                Task { @MainActor in completion(.failure(CameraError.nothingRecorded)) }
                return
            }
            let duration = CMTimeGetSeconds(CMTimeSubtract(lastVideoTime, startTime))
            writer.endSession(atSourceTime: lastVideoTime)
            videoWriterInput?.markAsFinished()
            audioWriterInput?.markAsFinished()
            let url = writer.outputURL
            resetWriter()
            writer.finishWriting {
                let ok = writer.status == .completed
                let error = writer.error
                Task { @MainActor in
                    if ok {
                        completion(.success(RecordedTake(url: url, duration: duration)))
                    } else {
                        completion(.failure(error ?? CameraError.writeFailed))
                    }
                }
            }
        }
    }

    private func resetWriter() {
        writer = nil
        videoWriterInput = nil
        audioWriterInput = nil
        writerStarted = false
    }

    private func makeWriter(for sample: CMSampleBuffer) -> Bool {
        guard let description = CMSampleBufferGetFormatDescription(sample) else { return false }
        let dims = CMVideoFormatDescriptionGetDimensions(description)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("take-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else { return false }

        let pixels = Int(dims.width) * Int(dims.height)
        let base = pixels >= 3840 * 2160 ? 40_000_000 : 14_000_000
        let bitrate = base * Int(fps) / 30
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: Int(dims.width),
            AVVideoHeightKey: Int(dims.height),
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ],
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitrate,
                AVVideoExpectedSourceFrameRateKey: Int(fps),
                AVVideoMaxKeyFrameIntervalKey: Int(fps)
            ]
        ]
        let video = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        video.expectsMediaDataInRealTime = true
        guard writer.canAdd(video) else { return false }
        writer.add(video)

        let audioSettings = audioOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) ?? [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 48_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128_000
        ]
        let audio = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audio.expectsMediaDataInRealTime = true
        if writer.canAdd(audio) { writer.add(audio) }

        writer.metadata = [Self.metadata(.commonIdentifierSoftware, "Teleprompter")]
        self.writer = writer
        videoWriterInput = video
        audioWriterInput = writer.inputs.contains(audio) ? audio : nil
        return true
    }

    private static func metadata(_ identifier: AVMetadataIdentifier, _ value: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString
        return item
    }

    // MARK: Interrupções

    @objc private func sessionInterrupted(_ notification: Notification) {
        Task { @MainActor [weak self] in self?.onInterrupted?() }
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        Task { @MainActor [weak self] in self?.onInterrupted?() }
        sessionQueue.async { [self] in
            if !session.isRunning { session.startRunning() }
        }
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output === audioOutput {
            handleAudio(sampleBuffer, connection: connection)
        } else {
            handleVideo(sampleBuffer)
        }
    }

    private func handleAudio(_ sample: CMSampleBuffer, connection: AVCaptureConnection) {
        onAudioSample?(sample)

        let now = CFAbsoluteTimeGetCurrent()
        if now - lastLevelReport > 0.08, let channel = connection.audioChannels.first {
            lastLevelReport = now
            // -50 dB (silêncio) a 0 dB (estourando) → 0 a 1.
            let level = max(0, min(1, (channel.averagePowerLevel + 50) / 50))
            Task { @MainActor [weak self] in self?.onAudioLevel?(level) }
        }

        guard wantsRecording, writerStarted, let input = audioWriterInput, input.isReadyForMoreMediaData else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sample)
        if CMTimeCompare(time, startTime) >= 0 { input.append(sample) }
    }

    private func handleVideo(_ sample: CMSampleBuffer) {
        guard wantsRecording else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sample)
        if writer == nil, !makeWriter(for: sample) {
            wantsRecording = false
            return
        }
        guard let writer, let input = videoWriterInput else { return }
        if !writerStarted {
            guard writer.startWriting() else {
                wantsRecording = false
                resetWriter()
                return
            }
            writer.startSession(atSourceTime: time)
            startTime = time
            writerStarted = true
            Task { @MainActor [weak self] in self?.onRecordingStarted?() }
        }
        if input.isReadyForMoreMediaData, input.append(sample) {
            lastVideoTime = time
        }
    }
}
