import Foundation
import UIKit
import CoreVideo
import CoreImage
import Accelerate
import Combine

/// Động cơ xếp chồng ảnh phơi sáng thiên văn thời gian thực (Real-time Live Stacking Pipeline)
/// Tương thích hoàn toàn với thuật toán của ChupAnhTV-fixed trên Android
final class AstroStackingEngine: ObservableObject {

    @Published var isStacking: Bool = false
    @Published var stackedFrames: Int = 0
    @Published var rejectedFrames: Int = 0
    @Published var totalExposureSeconds: Float = 0.0
    @Published var detectedStarCount: Int = 0
    @Published var histogramData: [Int]? = nil
    @Published var currentPreviewImage: UIImage? = nil

    // Cấu hình thuật toán
    @Published var selectedMode: StackingMode = .deepSkyAverage
    @Published var targetFrames: Int = 30
    @Published var midtoneStretch: Float = 0.18
    @Published var blackPoint: Float = 0.015

    // Bộ đệm tích lũy 32-bit float cho độ sâu màu và dải động cao
    private var accumulatorR: [Float]?
    private var accumulatorG: [Float]?
    private var accumulatorB: [Float]?
    private var accumulatorWidth: Int = 0
    private var accumulatorHeight: Int = 0

    // Căn chỉnh sao (Star alignment)
    private var referenceStars: [StarPoint]?
    private let processingQueue = DispatchQueue(label = "com.astrocam.stackingQueue", qos = .userInitiated)

    // Khung hình trực tiếp gần nhất
    private var latestPixelBuffer: CVPixelBuffer?
    private var latestImage: UIImage?
    private let lock = NSLock()

    func startStacking(mode: StackingMode? = nil, targetFrames: Int? = nil) {
        if let mode = mode { self.selectedMode = mode }
        if let target = targetFrames { self.targetFrames = target }

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
            calculateMetricsFromPixelBuffer(pixelBuffer)
            return
        }

        processingQueue.async { [weak self] in
            guard let self = self, self.isStacking else { return }
            self.performStackingOnPixelBuffer(pixelBuffer: pixelBuffer, exposureTime: exposureTime)
        }
    }

    /// Xử lý khung hình giả lập nhận từ SkySimulator
    func processBitmap(_ image: UIImage, exposureTime: Float) {
        lock.lock()
        latestImage = image
        lock.unlock()

        guard isStacking else {
            calculateMetricsFromImage(image)
            return
        }

        processingQueue.async { [weak self] in
            guard let self = self, self.isStacking else { return }
            self.performStackingOnImage(image: image, exposureTime: exposureTime)
        }
    }

    // MARK: - Core Stacking Logic

    private func performStackingOnImage(image: UIImage, exposureTime: Float) {
        guard let cgImage = image.cgImage else { return }
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
        ) else { return }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var curR = [Float](repeating: 0, count: width * height)
        var curG = [Float](repeating: 0, count: width * height)
        var curB = [Float](repeating: 0, count: width * height)
        var luma = [UInt8](repeating: 0, count: width * height)

        for i in 0..<(width * height) {
            let idx = i * 4
            let r = rgba[idx]
            let g = rgba[idx + 1]
            let b = rgba[idx + 2]

            curR[i] = Float(r) / 255.0
            curG[i] = Float(g) / 255.0
            curB[i] = Float(b) / 255.0

            let lum = (Int(r) * 2126 + Int(g) * 7152 + Int(b) * 722) / 10000
            luma[i] = UInt8(clamping: lum)
        }

        // Nhận diện sao
        let stars = StarDetector.detectStars(luminanceData: luma, width: width, height: height)
        DispatchQueue.main.async {
            self.detectedStarCount = stars.count
        }

        if selectedMode.requiresAlignment {
            if referenceStars == nil {
                if stars.count >= 4 {
                    referenceStars = stars
                } else {
                    DispatchQueue.main.async { self.rejectedFrames += 1 }
                    return
                }
            } else {
                if StarDetector.estimateOffset(refStars: referenceStars!, currentStars: stars) == nil {
                    DispatchQueue.main.async { self.rejectedFrames += 1 }
                    return
                }
            }
        }

        accumulate(curR: curR, curG: curG, curB: curB, width: width, height: height, exposureTime: exposureTime)
        updateHistogram(from: luma)
    }

    private func performStackingOnPixelBuffer(pixelBuffer: CVPixelBuffer, exposureTime: Float) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        guard pixelFormat == kCVPixelFormatType_32BGRA else { return }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        var curR = [Float](repeating: 0, count: width * height)
        var curG = [Float](repeating: 0, count: width * height)
        var curB = [Float](repeating: 0, count: width * height)
        var luma = [UInt8](repeating: 0, count: width * height)

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

                let lum = (Int(r) * 2126 + Int(g) * 7152 + Int(b) * 722) / 10000
                luma[dstIdx] = UInt8(clamping: lum)
            }
        }

        let stars = StarDetector.detectStars(luminanceData: luma, width: width, height: height)
        DispatchQueue.main.async {
            self.detectedStarCount = stars.count
        }

        if selectedMode.requiresAlignment {
            if referenceStars == nil {
                if stars.count >= 4 {
                    referenceStars = stars
                } else {
                    DispatchQueue.main.async { self.rejectedFrames += 1 }
                    return
                }
            } else {
                if StarDetector.estimateOffset(refStars: referenceStars!, currentStars: stars) == nil {
                    DispatchQueue.main.async { self.rejectedFrames += 1 }
                    return
                }
            }
        }

        accumulate(curR: curR, curG: curG, curB: curB, width: width, height: height, exposureTime: exposureTime)
        updateHistogram(from: luma)
    }

    private func accumulate(curR: [Float], curG: [Float], curB: [Float], width: Int, height: Int, exposureTime: Float) {
        if accumulatorR == nil || accumulatorWidth != width || accumulatorHeight != height {
            accumulatorWidth = width
            accumulatorHeight = height
            accumulatorR = curR
            accumulatorG = curG
            accumulatorB = curB

            DispatchQueue.main.async {
                self.stackedFrames = 1
                self.totalExposureSeconds = exposureTime
                self.currentPreviewImage = self.exportCurrentStackedBitmap()
            }
            return
        }

        let count = width * height
        let currentCount = stackedFrames

        switch selectedMode {
        case .deepSkyAverage:
            // Running Average: Acc = Acc * (N/(N+1)) + New * (1/(N+1))
            let factorOld = Float(currentCount) / Float(currentCount + 1)
            let factorNew = 1.0 / Float(currentCount + 1)

            for i in 0..<count {
                accumulatorR![i] = accumulatorR![i] * factorOld + curR[i] * factorNew
                accumulatorG![i] = accumulatorG![i] * factorOld + curG[i] * factorNew
                accumulatorB![i] = accumulatorB![i] * factorOld + curB[i] * factorNew
            }

        case .kappaSigma:
            // Kappa-Sigma Outlier Clipping: Lọc các vệ tinh và vệt máy bay bay ngang
            let factorOld = Float(currentCount) / Float(currentCount + 1)
            let factorNew = 1.0 / Float(currentCount + 1)

            for i in 0..<count {
                let diffR = abs(curR[i] - accumulatorR![i])
                let diffG = abs(curG[i] - accumulatorG![i])
                let diffB = abs(curB[i] - accumulatorB![i])

                // Nếu có vệt sáng dị thường (vệ tinh/máy bay) lớn hơn ngưỡng, bỏ qua điểm ảnh đó
                if diffR < 0.35 && diffG < 0.35 && diffB < 0.35 {
                    accumulatorR![i] = accumulatorR![i] * factorOld + curR[i] * factorNew
                    accumulatorG![i] = accumulatorG![i] * factorOld + curG[i] * factorNew
                    accumulatorB![i] = accumulatorB![i] * factorOld + curB[i] * factorNew
                }
            }

        case .starTrails:
            // Star Trails Max Intensity: Acc = max(Acc, New)
            for i in 0..<count {
                accumulatorR![i] = max(accumulatorR![i], curR[i])
                accumulatorG![i] = max(accumulatorG![i], curG[i])
                accumulatorB![i] = max(accumulatorB![i], curB[i])
            }
        }

        DispatchQueue.main.async {
            self.stackedFrames += 1
            self.totalExposureSeconds += exposureTime
            self.currentPreviewImage = self.exportCurrentStackedBitmap()

            if self.stackedFrames >= self.targetFrames {
                self.isStacking = false
            }
        }
    }

    private func updateHistogram(from luma: [UInt8]) {
        var bins = [Int](repeating: 0, count: 64)
        let step = 4
        for i in stride(from: 0, to: luma.count, by: step) {
            let bin = min(63, Int(luma[i]) / 4)
            bins[bin] += 1
        }
        DispatchQueue.main.async {
            self.histogramData = bins
        }
    }

    private func calculateMetricsFromImage(_ image: UIImage) {
        let stars = StarDetector.detectStars(from: image)
        DispatchQueue.main.async {
            self.detectedStarCount = stars.count
        }
    }

    private func calculateMetricsFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buf = base.assumingMemoryBound(to: UInt8.self)

        var bins = [Int](repeating: 0, count: 64)
        var lumaSamples = [UInt8]()
        let step = 8

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let idx = y * bytesPerRow + x * 4
                let b = Int(buf[idx])
                let g = Int(buf[idx + 1])
                let r = Int(buf[idx + 2])
                let lum = (r * 299 + g * 587 + b * 114) / 1000
                let bin = min(63, lum / 4)
                bins[bin] += 1
                lumaSamples.append(UInt8(clamping: lum))
            }
        }

        DispatchQueue.main.async {
            self.histogramData = bins
            self.detectedStarCount = StarDetector.detectStars(luminanceData: lumaSamples, width: width / step, height: height / step).count
        }
    }

    /// Xuất ảnh chụp thiên văn sau khi áp dụng MTF Midtone Stretch và Black Point Clipping
    func exportCurrentStackedBitmap() -> UIImage? {
        guard let r = accumulatorR, let g = accumulatorG, let b = accumulatorB,
              accumulatorWidth > 0, accumulatorHeight > 0 else {
            return exportLiveSnapshot()
        }

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

        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }

    /// Xuất ảnh thường từ khung hình xem trước hiện tại
    func exportLiveSnapshot() -> UIImage? {
        lock.lock()
        defer { lock.unlock() }

        if let img = latestImage {
            return img
        }

        if let buffer = latestPixelBuffer {
            let ciImage = CIImage(cvPixelBuffer: buffer)
            let context = CIContext()
            if let cg = context.createCGImage(ciImage, from: ciImage.extent) {
                return UIImage(cgImage: cg, scale: 1.0, orientation: .right)
            }
        }

        return nil
    }
}
