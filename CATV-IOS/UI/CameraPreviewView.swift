import SwiftUI
import AVFoundation

/// View hiển thị luồng khung ngắm camera (Viewfinder)
/// Hỗ trợ cả phần cứng Camera thật (AVCaptureVideoPreviewLayer) và chế độ giả lập bầu trời (SkySimulator)
struct CameraPreviewView: View {
    let session: AVCaptureSession
    var isSimMode: Bool
    var simImage: UIImage?

    var body: some View {
        ZStack {
            if isSimMode, let img = simImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                #if targetEnvironment(simulator)
                if let img = simImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.black
                }
                #else
                AVCameraPreviewLayerRepresentable(session: session)
                #endif
            }
        }
    }
}

/// Helper wrapper cho AVCaptureVideoPreviewLayer
struct AVCameraPreviewLayerRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if uiView.videoPreviewLayer.session != session {
            uiView.videoPreviewLayer.session = session
        }
    }

    class PreviewUIView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
        }
    }
}
