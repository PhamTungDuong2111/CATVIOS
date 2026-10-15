import UIKit
import CoreGraphics

/// Bộ giả lập bầu trời đêm thiên văn (Sky Simulator)
/// Mô phỏng dải Ngân Hà (Milky Way), các vì sao xoay theo góc quay của Trái Đất và nhiễu hạt cảm biến ISO cao
final class SkySimulator {
    let width: Int
    let height: Int

    private var rotationAngle: Float = 0.0

    private struct SimStar {
        let relX: Float
        let relY: Float
        let brightness: Float
        let radius: Float
    }

    private var stars: [SimStar] = []

    init(width: Int = 960, height: Int = 540) {
        self.width = width
        self.height = height

        // Khởi tạo danh mục 80 ngôi sao ngẫu nhiên phân bố quanh tâm thiên cầu
        var seed: UInt64 = 42
        func nextRandom() -> Float {
            seed = (seed &* 6364136223846793005) &+ 1442695040888963407
            let val = Double(seed >> 32) / Double(UInt32.max)
            return Float(val)
        }

        for _ in 0..<80 {
            let dist = nextRandom() * (Float(height) * 0.7)
            let angle = nextRandom() * (.pi * 2.0)
            let relX = cos(angle) * dist
            let relY = sin(angle) * dist
            let brightness = 140.0 + nextRandom() * 115.0 // 140 - 255
            let radius = 1.0 + nextRandom() * 2.2
            stars.append(SimStar(relX: relX, relY: relY, brightness: brightness, radius: radius))
        }
    }

    /// Tạo khung hình bầu trời đêm tiếp theo với các ngôi sao xoay dần
    func generateNextFrame() -> UIImage? {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let cgContext = context.cgContext

            // 1. Nền trời đêm tối thẳm (Deep Night Sky)
            cgContext.setFillColor(UIColor(red: 6/255.0, green: 9/255.0, blue: 16/255.0, alpha: 1.0).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))

            // 2. Dải sáng tinh vân Ngân Hà (Milky Way Nebula Glow)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradientColors: [CGColor] = [
                UIColor(red: 50/255.0, green: 80/255.0, blue: 140/255.0, alpha: 0.12).cgColor,
                UIColor(red: 120/255.0, green: 90/255.0, blue: 180/255.0, alpha: 0.22).cgColor,
                UIColor(red: 40/255.0, green: 70/255.0, blue: 120/255.0, alpha: 0.08).cgColor
            ]
            let colorLocations: [CGFloat] = [0.1, 0.5, 0.9]

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: colorLocations) {
                let startPoint = CGPoint(x: CGFloat(width) * 0.2, y: 0)
                let endPoint = CGPoint(x: CGFloat(width) * 0.8, y: CGFloat(height))
                cgContext.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
            }

            // 3. Vẽ các ngôi sao xoay quanh tâm thiên cực
            let centerX = Float(width) / 2.0
            let centerY = Float(height) / 2.0
            rotationAngle += 0.008

            let cosA = cos(rotationAngle)
            let sinA = sin(rotationAngle)

            for s in stars {
                let rotX = centerX + (s.relX * cosA - s.relY * sinA)
                let rotY = centerY + (s.relX * sinA + s.relY * cosA)

                if rotX >= 0 && rotX <= Float(width) && rotY >= 0 && rotY <= Float(height) {
                    let point = CGPoint(x: CGFloat(rotX), y: CGFloat(rotY))

                    // Quầng sáng mờ xung quanh (Halo Glow)
                    let haloRadius = CGFloat(s.radius * 2.4)
                    let haloAlpha = CGFloat((s.brightness / 255.0) * 0.35)
                    cgContext.setFillColor(UIColor(red: 200/255.0, green: 220/255.0, blue: 255/255.0, alpha: haloAlpha).cgColor)
                    cgContext.fillEllipse(in: CGRect(x: point.x - haloRadius, y: point.y - haloRadius, width: haloRadius * 2, height: haloRadius * 2))

                    // Nhân sao sáng (Core Star)
                    let coreRadius = CGFloat(s.radius)
                    let coreAlpha = CGFloat(s.brightness / 255.0)
                    cgContext.setFillColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: coreAlpha).cgColor)
                    cgContext.fillEllipse(in: CGRect(x: point.x - coreRadius, y: point.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2))
                }
            }
        }

        return image
    }
}
