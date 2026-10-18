import Foundation
import SwiftUI

/// Loại thiên thể trong Hệ Mặt Trời
enum CelestialBodyType: String, CaseIterable {
    case star = "STAR"
    case planet = "PLANET"
    case moon = "MOON"
    case sun = "SUN"
}

/// Thông tin chi tiết tọa độ và đặc tính thiên văn của một hành tinh/thiên thể
/// Tương thích 100% với PlanetInfo.kt trên Android
struct PlanetInfo: Identifiable, Equatable {
    let id: String
    let nameVi: String
    let nameEn: String
    let symbol: String
    let color: Color
    let glowColor: Color
    let altitude: Float        // Góc ngẩng (-90° đến +90°)
    let azimuth: Float         // Phương vị (0° đến 360°, 0=Bắc, 90=Đông, 180=Nam, 270=Tây)
    let distanceAu: Double     // Khoảng cách tới Trái Đất (AU)
    let magnitude: Float       // Độ sáng biểu kiến
    let constellationVi: String// Chòm sao hoàng đạo
    let constellationSymbol: String
    var type: CelestialBodyType = .planet
    let descriptionVi: String
    let observationTipVi: String
    let diameterKm: Int64
    var phasePercent: Int = 100 // Chỉ số phần trăm chiếu sáng (cho Mặt Trăng)

    var isAboveHorizon: Bool {
        altitude > 0.0
    }

    var formattedAltitude: String {
        String(format: "%+.1f°", altitude)
    }

    var formattedAzimuth: String {
        String(format: "%.0f° %@", azimuth, PlanetInfo.getAzimuthDirection(azimuth: azimuth))
    }

    var formattedDistance: String {
        if id == "MOON" {
            let km = Int64(distanceAu * 149597870.7)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let numStr = formatter.string(from: NSNumber(value: km)) ?? "\(km)"
            return "\(numStr) km"
        } else {
            let millionKm = Int64(distanceAu * 149.6)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let numStr = formatter.string(from: NSNumber(value: millionKm)) ?? "\(millionKm)"
            return String(format: "%.2f AU (%@ triệu km)", distanceAu, numStr)
        }
    }

    var formattedDiameter: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let diamStr = formatter.string(from: NSNumber(value: diameterKm)) ?? "\(diameterKm)"
        return "\(diamStr) km"
    }

    static func getAzimuthDirection(azimuth: Float) -> String {
        let norm = (azimuth.truncatingRemainder(dividingBy: 360.0) + 360.0).truncatingRemainder(dividingBy: 360.0)
        let idx = Int((norm + 22.5) / 45.0) % 8
        switch idx {
        case 0: return "Bắc (N)"
        case 1: return "Đông Bắc (NE)"
        case 2: return "Đông (E)"
        case 3: return "Đông Nam (SE)"
        case 4: return "Nam (S)"
        case 5: return "Tây Nam (SW)"
        case 6: return "Tây (W)"
        case 7: return "Tây Bắc (NW)"
        default: return "Bắc (N)"
        }
    }
}
