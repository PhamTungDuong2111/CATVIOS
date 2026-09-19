import Foundation
import UIKit
import CoreVideo
import CoreImage
import Accelerate
import Combine

/// Động cơ xếp chồng ảnh phơi sáng thiên văn thời gian thực (Real-time Live Stacking Pipeline)
final class AstroStackingEngine: ObservableObject {

    @Published var isStacking: Bool = false
    @Published var stackedFrames: Int = 0
    @Published var rejectedFrames: Int = 0
    @Published var totalExposureSeconds: Float = 0.0
    @Published var detectedStarCount: Int = 0
    @Published var histogramData: [Float] = [Float](repeating: 0, count: 64)

    // Cấu hình thuật toán
    var stackingMode: StackingMode = .deepSkyAverage
    var targetFrames: Int = 30
    var midtoneStretch: Float = 0.18
    var blackPoint: Float = 0.015

    // Bộ đệm tích lũy 32-bit float cho chất lượng HDR cao
    private var accumulatorR: [Float]?
    private var accumulatorG: [Float]?
    private var accumulatorB: [Float]?
    private var accumulatorWidth: Int = 0
    private var accumulatorHeight: Int = 0

    // Căn chỉnh sao (Star alignment)
    private var referenceStars: [StarPoint]?
    private let processingQueue = DispatchQueue(label = "com.astrocam.stackingQueue", qos = .userInitiated)

    // Khung hình trực tiếp gần nhất để xuất ảnh thường
    private var latestPixelBuffer: CVPixelBuffer?
    private let lock = NSLock()

    func startStacking() {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            self.resetStack()
            DispatchQueue.main.async {
                self.isStacking = true
            }
        }
    }

    func stopStacking() {
        DispatchQueue.main.async {
            self.isStacking = false
        }
    }

    func resetStack() {
        accumulatorR = nil
        accumulatorG = nil
        accumulatorB = nil
        accumulatorWidth = 0
        accumulatorHeight = 0
        referenceStars = nil

        DispatchQueue.main.async {
            self.stackedFrames = 0
            self.rejectedFrames = 0
            self.totalExposureSeconds = 0.0
            self.detectedStarCount = 0
        }
    }

    /// Xử lý khung hình nhận từ AVCaptureVideoDataOutput
    func processVideoFrame(_ pixelBuffer: CVPixelBuffer, exposureTime: Float) {
        lock.lock()
        latestPixelBuffer = pixelBuffer
        lock.unlock()

        guard isStacking else {
            // Chế độ xem trước: tính toán số lượng sao và histogram
            calculatePreviewMetrics(pixelBuffer)
            return
        }

        processingQueue.async { [weak self] in
            guard let self = self, self.isStacking else { return }
            self.performStacking(pixelBuffer: pixelBuffer, exposureTime: exposureTime)
        }
    }

    private func performStacking(pixelBuffer: CVPixelBuffer, exposureTime: Float) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        // 1. Trích xuất kênh màu và độ sáng (Grayscale)
        var luma = [UInt8](repeating: 0, count: width * height)
        var curR = [Float](repeating: 0, count: width * height)
        var curG = [Float](repeating: 0, count: width * height)
        var curB = [Float](repeating: 0, count: width * height)

        if pixelFormat == kCVPixelFormatType_32BGRA {
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let srcIdx = y * bytesPerRow + x * 4
                    let dstIdx = y * width + x

                    let b = buffer[srcIdx]
                    let g = buffer[srcIdx + 1]
                    let r = buffer[srcIdx + 2]

                    curR[dstIdx] = Float(r) / 255.0
                    curG[dstIdx] = Float(g) / 255.0
                    curB[dstIdx] = Float(b) / 255.0

                    // Rec. 709 luma
                    let lum = UInt8(clamping: Int(0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)))
                    luma[dstIdx] = lum
                }
            }
        } else {
            return
        }

        // 2. Nhận diện sao và căn chỉnh
        let stars = StarDetector.detectStars(luminanceData: luma, width: width, height: height)
        DispatchQueue.main.async {
            self.detectedStarCount = stars.count
        }

        if stackingMode.requiresAlignment {
            if referenceStars == nil {
                if stars.count >= 4 {
                    referenceStars = stars
                } else {
                    DispatchQueue.main.async { self.rejectedFrames += 1 }
                    return
                }
            } else {
                // Kiểm tra căn chỉnh
                if StarDetector.estimateOffset(refStars: referenceStars!, currentStars: stars) == nil {
                    DispatchQueue.main.async { self.rejectedFrames += 1 }
                    return
                }
            }
        }

        // 3. Khởi tạo Accumulator nếu chưa có
        if accumulatorR == nil || accumulatorWidth != width || accumulatorHeight != height {
            accumulatorWidth = width
            accumulatorHeight = height
            accumulatorR = curR
            accumulatorG = curG
            accumulatorB = curB

            DispatchQueue.main.async {
                self.stackedFrames = 1
                self.totalExposureSeconds = exposureTime
            }
            return
        }

        // 4. Cộng dồn theo chế độ
        let count = width * height
        let currentCount = stackedFrames

        switch stackingMode {
        case .deepSkyAverage, .kappaSigma:
            // Running Average: Acc = Acc * (N/(N+1)) + New * (1/(N+1))
            let factorOld = Float(currentCount) / Float(currentCount + 1)
            let factorNew = 1.0 / Float(currentCount + 1)

            for i in 0..<count {
                accumulatorR![i] = accumulatorR![i] * factorOld + curR[i] * factorNew
                accumulatorG![i] = accumulatorG![i] * factorOld + curG[i] * factorNew
                accumulatorB![i] = accumulatorB![i] * factorOld + curB[i] * factorNew
            }

        case .starTrailsMax:
            // Star Trails: Acc = max(Acc, New)
            for i in 0..<count {
                accumulatorR![i] = max(accumulatorR![i], curR[i])
                accumulatorG![i] = max(accumulatorG![i], curG[i])
                accumulatorB![i] = max(accumulatorB![i], curB[i])
            }
        }

        DispatchQueue.main.async {
            self.stackedFrames += 1
            self.totalExposureSeconds += exposureTime
            if self.stackedFrames >= self.targetFrames {
                self.isStacking = false
            }
        }
    }

    private func calculatePreviewMetrics(_ pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buf = base.assumingMemoryBound(to: UInt8.self)

        var bins = [Int](repeating: 0, count: 64)
        let sampleStep = 8

        for y in stride(from: 0, to: height, by: sampleStep) {
            for x in stride(from: 0, to: width, by: sampleStep) {
                let idx = y * bytesPerRow + x * 4
                let b = Int(buf[idx])
                let g = Int(buf[idx + 1])
                let r = Int(buf[idx + 2])
                let lum = (r * 299 + g * 587 + b * 114) / 1000
                let binIdx = min(63, lum / 4)
                bins[binIdx] += 1
            }
        }

        let maxVal = Float(bins.max() ?? 1)
        let normalized = bins.map { Float($0) / maxVal }

        DispatchQueue.main.async {
            self.histogramData = normalized
        }
    }

    /// Xuất ảnh chụp thường (Snapshot) từ khung hình xem trước hiện tại
    func exportLiveSnapshot() -> UIImage? {
        lock.lock()
        guard let buffer = latestPixelBuffer else {
            lock.unlock()
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: buffer)
        lock.unlock()

        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        }
        return nil
    }

    /// Xuất ảnh thiên văn sau khi đã áp dụng kéo dãn MTF Stretch
    func exportStackedResult() -> UIImage? {
        guard let r = accumulatorR, let g = accumulatorG, let b = accumulatorB,
              accumulatorWidth > 0, accumulatorHeight > 0 else { return nil }

        let w = accumulatorWidth
        let h = accumulatorHeight
        var outPixels = [UInt8](repeating: 255, count: w * h * 4)

        // Midtone Transfer Function: s(x) = ((m - 1) * x) / ((2 * m - 1) * x - m)
        let m = midtoneStretch
        let bp = blackPoint

        func stretch(_ x: Float) -> UInt8 {
            let clipped = max(0, (x - bp) / (1.0 - bp))
            guard clipped > 0 else { return 0 }
            guard clipped < 1.0 else { return 255 }
            let s = ((m - 1.0) * clipped) / ((2.0 * m - 1.0) * clipped - m)
            return UInt8(clamping: Int(min(1.0, max(0.0, s)) * 255.0))
        }

        for i in 0..<(w * h) {
            let idx = i * 4
            outPixels[idx] = stretch(r[i])     // R
            outPixels[idx + 1] = stretch(g[i]) // G
            outPixels[idx + 2] = stretch(b[i]) // B
            outPixels[idx + 3] = 255           // A
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let provider = CGDataProvider(data: Data(outPixels) as CFData),
              let cgImage = CGImage(
                width: w,
                height: h,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: w * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else { return nil }

        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}
