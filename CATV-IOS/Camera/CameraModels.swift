import Foundation
import UIKit

/// Các chế độ chụp ảnh/quay video chính của ứng dụng tương ứng phiên bản Android ChupAnhTV-fixed
enum AppCameraMode: String, CaseIterable, Identifiable {
    case photo = "PHOTO"
    case video = "VIDEO"
    case astro = "ASTRO"
    case pro = "PRO"

    var id: String { rawValue }

    /// Tiêu đề ngắn gọn hiển thị trên thanh chọn chế độ (Mode Carousel)
    var title: String {
        switch self {
        case .photo: return "ẢNH"
        case .video: return "VIDEO"
        case .astro: return "THIÊN VĂN"
        case .pro: return "CHUYÊN NGHIỆP"
        }
    }

    /// Tiêu đề đầy đủ hiển thị trên huy hiệu trạng thái đỉnh màn hình (Status Badge)
    var statusTitle: String {
        switch self {
        case .photo: return "ẢNH • TỰ ĐỘNG"
        case .video: return "VIDEO • FHD"
        case .astro: return "THIÊN VĂN"
        case .pro: return "CHUYÊN NGHIỆP"
        }
    }

    var displayName: String { title }
}

/// Các chế độ đèn Flash / Đèn pin
enum FlashMode: String, CaseIterable {
    case off = "OFF"
    case on = "ON"
    case auto = "AUTO"
    case torch = "TORCH"

    var icon: String {
        switch self {
        case .off: return "⚡\u{200D}✕"
        case .on, .torch: return "⚡"
        case .auto: return "⚡A"
        }
    }

    var color: UIColor {
        switch self {
        case .off: return .gray
        case .on, .torch: return UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        case .auto: return .white
        }
    }
}

/// Các chế độ xếp chồng phơi sáng thiên văn
enum StackingMode: String, CaseIterable, Identifiable {
    case deepSkyAverage = "DEEP_SKY_AVERAGE"
    case kappaSigma = "KAPPA_SIGMA"
    case starTrails = "STAR_TRAILS"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .deepSkyAverage: return "🌌 Ngân Hà"
        case .kappaSigma: return "🛰️ Khử Vệ Tinh"
        case .starTrails: return "🌠 Vệt Sao"
        }
    }

    var displayName: String {
        switch self {
        case .deepSkyAverage: return "Ngân Hà (Deep Sky)"
        case .kappaSigma: return "Khử Vệ Tinh (Kappa-Sigma)"
        case .starTrails: return "Vệt Sao (Star Trails)"
        }
    }

    var requiresAlignment: Bool {
        switch self {
        case .deepSkyAverage, .kappaSigma: return true
        case .starTrails: return false
        }
    }
}

/// Dữ liệu cảm biến con quay hồi chuyển & la bàn
struct OrientationData {
    var pitch: Float = 0.0      // Góc ngẩng bầu trời (-90° đến +90°)
    var roll: Float = 0.0       // Góc nghiêng chân trời (-180° đến +180°)
    var azimuth: Float = 0.0    // Hướng la bàn (0° - 360°)
    var isLevel: Bool = true    // Tripod đã cân bằng đường chân trời (±1.5°)

    var cardinalDirection: String {
        let index = Int(((azimuth + 22.5).truncatingRemainder(dividingBy: 360)) / 45.0)
        switch index {
        case 0: return "N (Bắc)"
        case 1: return "NE (Đông Bắc)"
        case 2: return "E (Đông)"
        case 3: return "SE (Đông Nam)"
        case 4: return "S (Nam)"
        case 5: return "SW (Tây Nam)"
        case 6: return "W (Tây)"
        case 7: return "NW (Tây Bắc)"
        default: return "N (Bắc)"
        }
    }
}

/// Trạng thái hoạt động hiện tại của Camera
struct CameraState {
    var mode: AppCameraMode = .photo
    var flashMode: FlashMode = .off
    var isFrontCamera: Bool = false
    var isRecordingVideo: Bool = false
    var recordingDurationSeconds: Int = 0

    // Phơi sáng & Lấy nét thủ công
    var isInfinityLocked: Bool = false
    var iso: Int = 1600
    var exposureTimeSeconds: Float = 1.0

    var minIso: Int = 100
    var maxIso: Int = 12800
    var minExposureSeconds: Float = 0.5
    var maxExposureSeconds: Float = 30.0
}
