import SwiftUI

/// Màn hình chính kết hợp toàn bộ giao diện và logic của ứng dụng CATV
struct MainCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var stackingEngine = AstroStackingEngine()
    @StateObject private var motionManager = MotionSensorManager()

    // Trạng thái giao diện
    @State private var showLeveler = false
    @State private var showHistogram = false
    @State private var isRedMode = false

    // Shutter flash effect
    @State private var isShutterFlashing = false

    // Modal xem chi tiết
    @State private var inspectedImage: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 1. Khung ngắm Camera trực tiếp
            CameraPreviewView(session: cameraManager.captureSession)
                .ignoresSafeArea()

            // 2. Lớp phủ Thước thủy cân bằng & La bàn
            if showLeveler {
                HorizonLevelerOverlay(motionManager: motionManager, isRedMode: isRedMode)
                    .ignoresSafeArea()
            }

            // 3. Hiệu ứng chớp sáng khi chụp ảnh (Shutter Flash)
            if isShutterFlashing {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.85)
                    .transition(.opacity)
            }

            // 4. Lớp phủ màu đêm (Night Red Filter Overlay)
            if isRedMode {
                Color.red.opacity(0.12)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // 5. Các thành phần điều khiển
            VStack(spacing: 0) {
                // Top Bar
                TopGlassBar(
                    cameraManager: cameraManager,
                    stackingEngine: stackingEngine,
                    showLeveler: $showLeveler,
                    showHistogram: $showHistogram,
                    isRedMode: $isRedMode
                )
                .padding(.top, 8)

                // Histogram nổi ở góc trên-phải nếu được bật
                if showHistogram {
                    HStack {
                        Spacer()
                        HistogramView(histogramData: stackingEngine.histogramData, isRedMode: isRedMode)
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                    }
                }

                Spacer()

                // Bảng điều khiển phơi sáng thiên văn / Pro (khi ở chế độ Astro hoặc Pro)
                if cameraManager.state.mode == .astro || cameraManager.state.mode == .pro {
                    AstroControlPanel(
                        cameraManager: cameraManager,
                        stackingEngine: stackingEngine,
                        isRedMode: isRedMode
                    )
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Băng chuyền chọn chế độ (Mode Carousel)
                ModeCarousel(
                    selectedMode: Binding(
                        get: { cameraManager.state.mode },
                        set: { cameraManager.setCameraMode($0) }
                    ),
                    isRedMode: isRedMode,
                    isDisabled: stackingEngine.isStacking || cameraManager.state.isRecordingVideo
                )
                .padding(.bottom, 16)

                // Thanh nút bấm đáy (Shutter, Thumbnail, Flip)
                BottomControlBar(
                    cameraManager: cameraManager,
                    stackingEngine: stackingEngine,
                    isRedMode: isRedMode,
                    onShutterTapped: {
                        handleShutterAction()
                    },
                    onThumbnailTapped: {
                        if let thumb = cameraManager.lastCapturedThumbnail {
                            inspectedImage = thumb
                        }
                    }
                )
            }
        }
        .onAppear {
            // Nối luồng dữ liệu khung hình camera vào bộ xếp chồng thiên văn
            cameraManager.onVideoFrameAvailable = { pixelBuffer, exposureTime in
                stackingEngine.processVideoFrame(pixelBuffer, exposureTime: exposureTime)
            }

            cameraManager.onPhotoCaptured = { image in
                if let img = image {
                    inspectedImage = img
                }
            }
        }
        .sheet(item: Binding<IdentifiableImage?>(
            get: { inspectedImage.map { IdentifiableImage(image: $0) } },
            set: { inspectedImage = $0?.image }
        )) { item in
            CapturedMediaDetailSheet(
                image: item.image,
                modeName: cameraManager.state.mode.displayName,
                stackedCount: stackingEngine.stackedFrames,
                rejectedCount: stackingEngine.rejectedFrames,
                totalExposure: stackingEngine.totalExposureSeconds,
                isRedMode: isRedMode,
                onDismiss: {
                    inspectedImage = nil
                }
            )
        }
    }

    private func handleShutterAction() {
        switch cameraManager.state.mode {
        case .photo:
            triggerShutterFlash()
            cameraManager.takePhoto()

        case .video:
            cameraManager.toggleVideoRecording()

        case .astro:
            if stackingEngine.isStacking {
                stackingEngine.stopStacking()
                // Xuất ảnh thiên văn sau khi hoàn thành xếp chồng
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let result = stackingEngine.exportStackedResult() {
                        cameraManager.lastCapturedThumbnail = result
                        inspectedImage = result
                        PhotoLibraryExporter.saveImageToPhotoLibrary(result) { _, _ in }
                    }
                }
            } else {
                stackingEngine.startStacking()
            }

        case .pro:
            triggerShutterFlash()
            cameraManager.takePhoto()
        }
    }

    private func triggerShutterFlash() {
        isShutterFlashing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.15)) {
                isShutterFlashing = false
            }
        }
    }
}

/// Helper bọc UIImage để hỗ trợ SwiftUI .sheet(item:)
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
