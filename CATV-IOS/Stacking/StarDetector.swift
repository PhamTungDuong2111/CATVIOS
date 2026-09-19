import Foundation
import CoreGraphics
import Accelerate

/// Cấu trúc đại diện cho một điểm sao sáng trên bầu trời
struct StarPoint {
    var x: Float
    var y: Float
    var brightness: Float
    var size: Float
}

/// Thuật toán nhận diện điểm sao và ước tính độ dịch chuyển giữa các khung hình
final class StarDetector {

    /// Phát hiện các điểm sao sáng từ dữ liệu độ sáng (Grayscale buffer)
    static func detectStars(
        luminanceData: [UInt8],
        width: Int,
        height: Int,
        threshold: Float = 3.0,
        maxStars: Int = 100
    ) -> [StarPoint] {
        guard width > 0, height > 0, luminanceData.count >= width * height else { return [] }

        // 1. Tính toán giá trị độ sáng trung bình và độ lệch chuẩn
        var mean: Float = 0
        var stdDev: Float = 0
        var floatArray = [Float](repeating: 0, count: luminanceData.count)

        vDSP_vfltu8(luminanceData, 1, &floatArray, 1, vDSP_Length(luminanceData.count))
        vDSP_normalize(floatArray, 1, nil, 1, &mean, &stdDev, vDSP_Length(luminanceData.count))

        let cutoff = mean + threshold * stdDev
        var stars: [StarPoint] = []

        // 2. Quét tìm các cực đại địa phương (Local Maxima) 3x3
        let step = 3
        for y in stride(from: 4, to: height - 4, by: step) {
            for x in stride(from: 4, to: width - 4, by: step) {
                let idx = y * width + x
                let val = floatArray[idx]

                if val > cutoff {
                    // Kiểm tra xem có phải điểm sáng nhất trong ô lân cận 3x3 không
                    if val > floatArray[idx - 1] && val > floatArray[idx + 1] &&
                       val > floatArray[idx - width] && val > floatArray[idx + width] {

                        // Tính trọng tâm (Centroid) để đạt độ chính xác sub-pixel
                        var sumW: Float = 0
                        var sumX: Float = 0
                        var sumY: Float = 0

                        for dy in -1...1 {
                            for dx in -1...1 {
                                let w = floatArray[(y + dy) * width + (x + dx)]
                                sumW += w
                                sumX += Float(x + dx) * w
                                sumY += Float(y + dy) * w
                            }
                        }

                        if sumW > 0 {
                            let cx = sumX / sumW
                            let cy = sumY / sumW
                            stars.append(StarPoint(x: cx, y: cy, brightness: val, size: 1.5))
                        }

                        if stars.count >= maxStars {
                            return stars
                        }
                    }
                }
            }
        }

        return stars
    }

    /// Ước tính độ dịch chuyển offset (dx, dy) giữa khung hình tham chiếu và khung hình hiện tại
    static func estimateOffset(refStars: [StarPoint], currentStars: [StarPoint]) -> CGPoint? {
        guard refStars.count >= 4, currentStars.count >= 4 else { return nil }

        // Sử dụng matching đơn giản các sao sáng nhất
        let topRef = Array(refStars.prefix(10))
        let topCur = Array(currentStars.prefix(10))

        var totalDx: CGFloat = 0
        var totalDy: CGFloat = 0
        var matchCount: CGFloat = 0

        for r in topRef {
            if let closest = topCur.min(by: {
                let d1 = hypot(Double($0.x - r.x), Double($0.y - r.y))
                let d2 = hypot(Double($1.x - r.x), Double($1.y - r.y))
                return d1 < d2
            }) {
                let dist = hypot(Double(closest.x - r.x), Double(closest.y - r.y))
                if dist < 50.0 { // Giới hạn dịch chuyển hợp lý giữa 2 khung liền kề
                    totalDx += CGFloat(closest.x - r.x)
                    totalDy += CGFloat(closest.y - r.y)
                    matchCount += 1
                }
            }
        }

        guard matchCount >= 3 else { return nil }
        return CGPoint(x: totalDx / matchCount, y: totalDy / matchCount)
    }
}
