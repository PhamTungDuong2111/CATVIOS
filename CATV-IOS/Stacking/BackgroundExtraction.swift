import UIKit

/// Thuật toán khử ô nhiễm ánh sáng nền trời đêm (Background Gradient Extraction & Flattening)
/// Tương thích 100% với BackgroundExtraction.kt trên Android
enum BackgroundExtraction {

    /// Ước tính gradient ô nhiễm ánh sáng tại 4 góc khung hình và trừ bỏ gradient
    /// để tạo nền trời phẳng, đen tuyền và làm nổi bật dải Ngân Hà
    static func removeGradient(from source: UIImage) -> UIImage? {
        guard let cgImage = source.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &rgba,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let sampleSize = max(10, min(width / 40, height / 40))

        let tl = sampleCornerBrightness(pixels: rgba, width: width, startX: 0, startY: 0, size: sampleSize)
        let tr = sampleCornerBrightness(pixels: rgba, width: width, startX: width - sampleSize, startY: 0, size: sampleSize)
        let bl = sampleCornerBrightness(pixels: rgba, width: width, startX: 0, startY: height - sampleSize, size: sampleSize)
        let br = sampleCornerBrightness(pixels: rgba, width: width, startX: width - sampleSize, startY: height - sampleSize, size: sampleSize)

        let invW = 1.0 / Float(width)
        let invH = 1.0 / Float(height)

        for y in 0..<height {
            let vRatio = Float(y) * invH
            let rowOffset = y * width * 4
            let topRow = tl * (1.0 - vRatio) + bl * vRatio
            let botRow = tr * (1.0 - vRatio) + br * vRatio
            let diffRow = botRow - topRow

            for x in 0..<width {
                let uRatio = Float(x) * invW
                let bgEstimate = topRow + diffRow * uRatio

                let idx = rowOffset + x * 4
                let r = Float(rgba[idx])
                let g = Float(rgba[idx + 1])
                let b = Float(rgba[idx + 2])

                let sub = bgEstimate * 255.0
                rgba[idx] = UInt8(clamping: Int(max(0.0, r - sub)))
                rgba[idx + 1] = UInt8(clamping: Int(max(0.0, g - sub)))
                rgba[idx + 2] = UInt8(clamping: Int(max(0.0, b - sub)))
            }
        }

        guard let outputProvider = CGDataProvider(data: Data(rgba) as CFData),
              let outCgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: outputProvider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else { return nil }

        return UIImage(cgImage: outCgImage, scale: source.scale, orientation: source.imageOrientation)
    }

    private static func sampleCornerBrightness(pixels: [UInt8], width: Int, startX: Int, startY: Int, size: Int) -> Float {
        var minLum: Float = 1.0

        for y in startY..<(startY + size) {
            let rowOffset = y * width * 4
            for x in startX..<(startX + size) {
                let idx = rowOffset + x * 4
                let r = Float(pixels[idx]) / 255.0
                let g = Float(pixels[idx + 1]) / 255.0
                let b = Float(pixels[idx + 2]) / 255.0
                let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                if lum < minLum {
                    minLum = lum
                }
            }
        }
        return minLum
    }
}
