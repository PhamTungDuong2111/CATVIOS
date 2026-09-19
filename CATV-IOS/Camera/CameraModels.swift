import Foundation
import AVFoundation

/// Các chế độ chụp ảnh/quay video chính của ứng dụng
enum AppCameraMode: String, CaseIterable, Identifiable {
    case photo = "CHỤP ẢNH"
    case video = "QUAY VIDEO"
    case astro = "THIÊN VĂN"
    case pro = "CHUYÊN NGHIỆP"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

/// Các chế độ đèn Flash / Đèn pin
enum FlashMode: String, CaseIterable {
    case off = "Tắt"
    case on = "Bật"
    case auto = "Tự động"
    case torch = "Đèn pin"

    var iconName: String {
        switch self {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        case .torch: return "flashlight.on.fill"
        }
    }
}

/// Các chế độ xếp chồng phơi sáng thiên văn
enum StackingMode: String, CaseIterable, Identifiable {
    case deepSkyAverage = "Deep Sky (Trung bình)"
    case starTrailsMax = "Star Trails (Vệt sao)"
    case kappaSigma = "Khử vệ tinh (Kappa-Sigma)"

    var id: String { rawValue }

    var requiresAlignment: Boolean {
        switch self {
        case .deepSkyAverage, .kappaSigma: return true
        case .starTrailsMax: return false
        }
    }
}

typealias Boolean = Bool

/// Trạng thái hoạt động hiện tại của Camera
struct CameraState {
    var mode: AppCameraMode = .photo
    var flashMode: FlashMode = .off
    var isFrontCamera: Bool = false
    var isRecordingVideo: Bool = false
    var recordingDurationSeconds: Int = 0

    // Phơi sáng & Cảm biến
    var iso: Float = 100.0
    var exposureDurationSeconds: Float = 0.05
    var focusDistance: Float = 1.0 // 1.0 = vô cực cho thiên văn

    var minIso: Float = 50.0
    var maxIso: Float = 3200.0
    var minExposureSeconds: Float = 0.001
    var maxExposureSeconds: Float = 1.0
}
