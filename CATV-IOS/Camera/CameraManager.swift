import Foundation
import AVFoundation
import UIKit
import Combine

/// Quản lý phần cứng Camera qua AVFoundation (AVCaptureSession, Photo, Video, Torch, ISO, Shutter)
final class CameraManager: NSObject, ObservableObject {

    @Published var state = CameraState()
    @Published var isSessionRunning = false
    @Published var lastCapturedThumbnail: UIImage?

    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label = "com.astrocam.sessionQueue")

    private var activeVideoDevice: AVCaptureDevice?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?

    private let photoOutput = AVCapturePhotoOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()

    private var currentVideoURL: URL?
    private var recordingTimer: Timer?

    // Delegate chuyển tiếp frame cho bộ xếp chồng thiên văn
    var onVideoFrameAvailable: ((CVPixelBuffer, Float) -> Void)?

    // Callbacks
    var onPhotoCaptured: ((UIImage?) -> Void)?
    var onVideoRecorded: ((URL?) -> Void)?

    override init() {
        super.init()
        checkPermissionsAndSetup()
    }

    private func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCaptureSession()
                }
            }
        default:
            break
        }
    }

    func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            // 1. Video Input (Camera sau mặc định)
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: camera) else {
                self.captureSession.commitConfiguration()
                return
            }

            self.activeVideoDevice = camera
            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
                self.videoDeviceInput = videoInput
            }

            // 2. Audio Input (Micro thu âm)
            if let mic = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: mic) {
                if self.captureSession.canAddInput(audioInput) {
                    self.captureSession.addInput(audioInput)
                    self.audioDeviceInput = audioInput
                }
            }

            // 3. Photo Output
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
            }

            // 4. Movie File Output (Quay video)
            if self.captureSession.canAddOutput(self.movieFileOutput) {
                self.captureSession.addOutput(self.movieFileOutput)
            }

            // 5. Video Data Output (Frame stream cho Stacking)
            if self.captureSession.canAddOutput(self.videoDataOutput) {
                self.captureSession.addOutput(self.videoDataOutput)
                self.videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                ]
                self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label = "com.astrocam.frameQueue"))
            }

            self.updateCameraCapabilities(camera)
            self.captureSession.commitConfiguration()

            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
                self.applyModeSettings(self.state.mode)
            }
        }
    }

    private func updateCameraCapabilities(_ device: AVCaptureDevice) {
        let minIso = device.activeFormat.minISO
        let maxIso = device.activeFormat.maxISO
        let minExp = Float(CMTimeGetSeconds(device.activeFormat.minExposureDuration))
        let maxExp = Float(CMTimeGetSeconds(device.activeFormat.maxExposureDuration))

        DispatchQueue.main.async {
            self.state.minIso = minIso
            self.state.maxIso = maxIso
            self.state.minExposureSeconds = minExp
            self.state.maxExposureSeconds = maxExp
            self.state.iso = min(max(100.0, minIso), maxIso)
        }
    }

    // MARK: - Chuyển đổi chế độ (Mode Switching)

    func setCameraMode(_ mode: AppCameraMode) {
        state.mode = mode
        applyModeSettings(mode)
    }

    private func applyModeSettings(_ mode: AppCameraMode) {
        guard let device = activeVideoDevice else { return }

        try? device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        switch mode {
        case .photo, .video:
            // Tự động lấy nét và đo sáng như máy ảnh tiêu chuẩn
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }

        case .astro, .pro:
            // Khóa lấy nét ở vô cực và cho phép chỉnh tay ISO / Shutter Speed
            if device.isFocusModeSupported(.locked) {
                device.setFocusModeLocked(lensPosition: 1.0, completionHandler: nil)
            }
            applyManualExposure(iso: state.iso, duration: state.exposureDurationSeconds)
        }
    }

    func setManualExposure(iso: Float, duration: Float) {
        state.iso = iso
        state.exposureDurationSeconds = duration
        if state.mode == .astro || state.mode == .pro {
            applyManualExposure(iso: iso, duration: duration)
        }
    }

    private func applyManualExposure(iso: Float, duration: Float) {
        guard let device = activeVideoDevice else { return }
        try? device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        let clampedIso = min(max(iso, device.activeFormat.minISO), device.activeFormat.maxISO)
        let clampedDuration = min(max(duration, Float(CMTimeGetSeconds(device.activeFormat.minExposureDuration))), Float(CMTimeGetSeconds(device.activeFormat.maxExposureDuration)))
        let time = CMTimeMakeWithSeconds(Float64(clampedDuration), preferredTimescale: 1000000)

        device.setExposureModeCustom(duration: time, iso: clampedIso, completionHandler: nil)
    }

    // MARK: - Flash & Torch Controls

    func toggleFlash() {
        let allModes = FlashMode.allCases
        if let idx = allModes.firstIndex(of: state.flashMode) {
            let nextMode = allModes[(idx + 1) % allModes.count]
            setFlashMode(nextMode)
        }
    }

    func setFlashMode(_ mode: FlashMode) {
        state.flashMode = mode
        guard let device = activeVideoDevice, device.hasTorch else { return }

        try? device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        if mode == .torch {
            try? device.setTorchModeOn(level: 1.0)
        } else {
            device.torchMode = .off
        }
    }

    // MARK: - Chuyển đổi Camera Trước / Sau (Flip Camera)

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let currentPosition = self.videoDeviceInput?.device.position ?? .back
            let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back

            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }

            self.captureSession.beginConfiguration()
            if let oldInput = self.videoDeviceInput {
                self.captureSession.removeInput(oldInput)
            }

            if self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
                self.videoDeviceInput = newInput
                self.activeVideoDevice = newDevice
            }

            self.updateCameraCapabilities(newDevice)
            self.captureSession.commitConfiguration()

            DispatchQueue.main.async {
                self.state.isFrontCamera = (newPosition == .front)
                self.applyModeSettings(self.state.mode)
            }
        }
    }

    // MARK: - Chụp ảnh (Photo Capture)

    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        switch state.flashMode {
        case .on: settings.flashMode = .on
        case .off: settings.flashMode = .off
        case .auto: settings.flashMode = .auto
        case .torch: settings.flashMode = .off
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Quay Video (Video Recording)

    func toggleVideoRecording() {
        if movieFileOutput.isRecording {
            stopVideoRecording()
        } else {
            startVideoRecording()
        }
    }

    private func startVideoRecording() {
        guard !movieFileOutput.isRecording else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("CATV_\(Int(Date().timeIntervalSince1970)).mp4")
        currentVideoURL = fileURL

        movieFileOutput.startRecording(to: fileURL, recordingDelegate: self)

        state.isRecordingVideo = true
        state.recordingDurationSeconds = 0

        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.state.recordingDurationSeconds += 1
            }
        }
    }

    private func stopVideoRecording() {
        guard movieFileOutput.isRecording else { return }
        movieFileOutput.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil
        state.isRecordingVideo = false
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            onPhotoCaptured?(nil)
            return
        }

        DispatchQueue.main.async {
            self.lastCapturedThumbnail = image
            self.onPhotoCaptured?(image)
        }

        // Tự động lưu vào Photo Library
        PhotoLibraryExporter.saveImageToPhotoLibrary(image) { success, err in
            if success {
                print("Đã lưu ảnh chụp vào Photos thành công!")
            }
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        state.isRecordingVideo = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        guard error == nil else {
            print("Lỗi quay video: \(String(describing: error))")
            onVideoRecorded?(nil)
            return
        }

        // Tạo thumbnail từ video
        let asset = AVAsset(url: outputFileURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.5, preferredTimescale: 60)
        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            DispatchQueue.main.async {
                self.lastCapturedThumbnail = UIImage(cgImage: cgImage)
            }
        }

        // Tự động lưu vào Photo Library
        PhotoLibraryExporter.saveVideoToPhotoLibrary(fileURL: outputFileURL) { [weak self] success, _ in
            if success {
                print("Đã lưu video vào Photos thành công!")
            }
            self?.onVideoRecorded?(outputFileURL)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: [AVCaptureConnection]) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let duration = state.exposureDurationSeconds
        onVideoFrameAvailable?(pixelBuffer, duration)
    }
}
