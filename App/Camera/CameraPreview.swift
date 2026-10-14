import AVFoundation
import SwiftUI
import UIKit

/// A imagem da câmera, em tela cheia. Toque foca e mede a luz no ponto; toque longo trava (AE/AF).
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var onFocus: (_ devicePoint: CGPoint, _ viewPoint: CGPoint, _ lock: Bool) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onFocus = onFocus
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        view.onFocus = onFocus
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        var onFocus: ((CGPoint, CGPoint, Bool) -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
            let long = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
            long.minimumPressDuration = 0.6
            addGestureRecognizer(long)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }

        @objc private func tapped(_ gesture: UITapGestureRecognizer) {
            report(gesture.location(in: self), lock: false)
        }

        @objc private func longPressed(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            report(gesture.location(in: self), lock: true)
        }

        private func report(_ point: CGPoint, lock: Bool) {
            let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
            onFocus?(devicePoint, point, lock)
        }
    }
}
