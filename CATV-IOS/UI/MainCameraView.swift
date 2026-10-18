import SwiftUI

/// Màn hình chính kết hợp toàn bộ tính năng và giao diện của ChupAnhTV-fixed cho iOS
/// Tương thích 100% với AstroAppScreen.kt trên Android
struct MainCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var stackingEngine = AstroStackingEngine()
    @StateObject private var motionManager = MotionSensorManager()
    @StateObject private var locationManager = AstroLocationManager()

    // Trạng thái giao diện
    @State private var showLeveler = false
    @State private var showHistogram = false
    @State private var showPlanetOverlay = true // Mặc định bật AR hành tinh như Android
    @State private var showPlanetBar = false
    @State private var isRedMode = false
    @State private var isSimMode = false

    // Vị trí các hành tinh trong Hệ Mặt Trời
    @State private var currentPlanets: [PlanetInfo] = []
    @State private var selectedPlanet: PlanetInfo?
    @State private var targetedPlanet: PlanetInfo?
    @State private var planetTimer: Timer?

    // Shutter flash effect
    @State private var isShutterFlashing = false

    // Modal xem chi tiết kết quả
    @State private var previewImage: UIImage?

    // Khung hình giả lập bầu trời thời gian thực
    @State private var simulatedSkyImage: UIImage?
    private let skySim = SkySimulator()
    @State private var simTimer: Timer?

    // Thông báo Toast như Android
    @State private var toastMessage: String?

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.165, blue: 0.294) : Color(red: 0.0, green: 0.898, blue: 1.0)
    }

    var visiblePlanetCount: Int {
        currentPlanets.filter { $0.isAboveHorizon }.count
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 1. Khung ngắm Camera trực tiếp (Live Viewfinder hoặc SkySimulator)
            CameraPreviewView(
                session: cameraManager.captureSession,
                isSimMode: isSimMode,
                simImage: simulatedSkyImage
            )
            .ignoresSafeArea()

            // 2. Thước thủy chân trời & La bàn (Artificial Horizon Leveler & Reticle)
            if showLeveler {
                HorizonLevelerOverlay(
                    motionManager: motionManager,
                    isRedMode: isRedMode,
                    showGrid: true
                )
                .ignoresSafeArea()
            }

            // 2b. Lớp phủ Thực tế Tăng cường AR các Hành tinh (Solar System Planetary AR Overlay)
            if showPlanetOverlay {
                PlanetOverlay(
                    planets: currentPlanets,
                    orientation: motionManager.orientation,
                    isRedMode: isRedMode,
                    selectedPlanet: selectedPlanet,
                    targetedPlanet: targetedPlanet,
                    onPlanetSelected: { planet in
                        selectedPlanet = planet
                    }
                )
                .ignoresSafeArea()
            }

            // 3. Hiệu ứng chớp sáng khi bấm chụp (Shutter Flash Effect)
            if isShutterFlashing {
                Color.white.opacity(0.75)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // 4. Lớp lọc bảo vệ mắt ban đêm (Red Night Mode Overlay)
            if isRedMode {
                Color.red.opacity(0.12)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // 5. CÁC THÀNH PHẦN ĐIỀU KHIỂN CHÍNH
            VStack(spacing: 0) {
                // TOP HUD BAR
                TopGlassBar(
                    cameraManager: cameraManager,
                    stackingEngine: stackingEngine,
                    showLeveler: $showLeveler,
                    showHistogram: $showHistogram,
                    showPlanetOverlay: $showPlanetOverlay,
                    showPlanetBar: $showPlanetBar,
                    isRedMode: $isRedMode,
                    isSimMode: isSimMode,
                    visiblePlanetCount: visiblePlanetCount
                )
                .padding(.top, 8)

                // Thanh tra cứu hành tinh nhanh thả nổi (Collapsible Planet Quick Bar)
                if showPlanetBar && cameraManager.state.mode == .astro {
                    PlanetQuickBar(
                        planets: currentPlanets,
                        selectedPlanet: selectedPlanet,
                        targetedPlanet: targetedPlanet,
                        isRedMode: isRedMode,
                        onPlanetSelected: { planet in
                            selectedPlanet = planet
                        },
                        onPlanetTargetToggle: { planet in
                            if targetedPlanet?.id == planet.id {
                                targetedPlanet = nil
                            } else {
                                targetedPlanet = planet
                            }
                        },
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPlanetBar = false
                            }
                        }
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Mini Histogram thả nổi góc trên-phải nếu bật
                if showHistogram {
                    HStack {
                        Spacer()
                        HistogramView(
                            histogramData: stackingEngine.histogramData,
                            isRedMode: isRedMode
                        )
                        .padding(.trailing, 16)
                        .padding(.top, 6)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }

                Spacer()

                // BOTTOM CAMERA INTERFACE
                VStack(spacing: 0) {
                    // Bảng điều khiển thiên văn (Chỉ hiện khi ở chế độ ASTRO hoặc PRO)
                    if cameraManager.state.mode == .astro || cameraManager.state.mode == .pro {
                        AstroControlPanel(
                            cameraManager: cameraManager,
                            stackingEngine: stackingEngine,
                            isSimMode: $isSimMode,
                            isRedMode: isRedMode
                        )
                        .padding(.bottom, 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Băng chuyền chọn chế độ (Mode Selector Carousel: ẢNH, VIDEO, THIÊN VĂN, PRO)
                    ModeCarousel(
                        selectedMode: Binding(
                            get: { cameraManager.state.mode },
                            set: { cameraManager.setCameraMode($0) }
                        ),
                        isRedMode: isRedMode,
                        isDisabled: stackingEngine.isStacking || cameraManager.state.isRecordingVideo
                    )

                    // Thanh Shutter đáy (Bottom Shutter Bar)
                    BottomControlBar(
                        cameraManager: cameraManager,
                        stackingEngine: stackingEngine,
                        isRedMode: isRedMode,
                        onShutterTapped: {
                            handleShutterAction()
                        },
                        onThumbnailTapped: {
                            handleThumbnailAction()
                        }
                    )
                }
            }

            // 6. Toast Notification nổi giữa màn hình
            if let toast = toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(accentColor.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.bottom, 120)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }

            // 7. Planet Detail Dialog (Hộp thoại chi tiết hành tinh)
            if let planet = selectedPlanet {
                PlanetDetailDialog(
                    planet: planet,
                    isTargeted: targetedPlanet?.id == planet.id,
                    isRedMode: isRedMode,
                    onTargetToggle: { p in
                        if targetedPlanet?.id == p.id {
                            targetedPlanet = nil
                        } else {
                            targetedPlanet = p
                        }
                    },
                    onDismiss: {
                        selectedPlanet = nil
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onAppear {
            setupCallbacks()
            startPlanetCalculations()
            #if targetEnvironment(simulator)
            isSimMode = true
            #endif
        }
        .onDisappear {
            stopPlanetCalculations()
        }
        .onChange(of: isSimMode) { active in
            if active {
                startSkySimulation()
            } else {
                stopSkySimulation()
            }
        }
        .sheet(item: Binding<IdentifiableImage?>(
            get: { previewImage.map { IdentifiableImage(image: $0) } },
            set: { previewImage = $0?.image }
        )) { item in
            CapturedMediaDetailSheet(
                image: item.image,
                modeName: cameraManager.state.mode.displayName,
                stackedCount: stackingEngine.stackedFrames,
                rejectedCount: stackingEngine.rejectedFrames,
                totalExposure: stackingEngine.totalExposureSeconds,
                isRedMode: isRedMode,
                onDismiss: {
                    previewImage = nil
                }
            )
        }
    }

    // MARK: - Actions

    private func handleShutterAction() {
        switch cameraManager.state.mode {
        case .photo:
            triggerShutterFlash()
            cameraManager.takePhoto { bmp, uri in
                if bmp != nil {
                    showToast("✅ Đã lưu ảnh vào Thư viện!")
                } else {
                    showToast("❌ Lỗi chụp ảnh")
                }
            }

        case .video:
            if cameraManager.state.isRecordingVideo {
                cameraManager.stopRecording { url in
                    if url != nil {
                        showToast("✅ Đã lưu video vào Thư viện!")
                    } else {
                        showToast("❌ Không thể lưu video")
                    }
                }
            } else {
                cameraManager.startRecording(
                    onStarted: { showToast("🔴 Đang quay video...") },
                    onError: { err in showToast(err) }
                )
            }

        case .astro:
            if stackingEngine.isStacking {
                stackingEngine.stopStacking()
                // Khôi phục chế độ xem trực tiếp
                cameraManager.setCameraMode(.astro)
                showToast("Đã hoàn tất phơi sáng!")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let bmp = stackingEngine.exportCurrentStackedBitmap() {
                        cameraManager.lastCapturedThumbnail = bmp
                        previewImage = bmp
                    }
                }
            } else {
                // Áp dụng phơi sáng thủ công khi bắt đầu chuỗi xếp chồng
                cameraManager.setIso(cameraManager.state.iso)
                cameraManager.setExposureTime(cameraManager.state.exposureTimeSeconds)
                stackingEngine.startStacking(mode: stackingEngine.selectedMode, targetFrames: stackingEngine.targetFrames)
            }

        case .pro:
            triggerShutterFlash()
            cameraManager.takePhoto { bmp, uri in
                if bmp != nil {
                    showToast("✅ Đã chụp ảnh PRO!")
                }
            }
        }
    }

    private func handleThumbnailAction() {
        if let thumb = cameraManager.lastCapturedThumbnail {
            previewImage = thumb
        } else if stackingEngine.stackedFrames > 0 && !stackingEngine.isStacking {
            if let bmp = stackingEngine.exportCurrentStackedBitmap() {
                previewImage = bmp
            } else {
                showToast("Chưa có ảnh hoàn chỉnh")
            }
        } else {
            showToast("Chưa có ảnh chụp nào")
        }
    }

    private func triggerShutterFlash() {
        isShutterFlashing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.15)) {
                isShutterFlashing = false
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }

    private func setupCallbacks() {
        cameraManager.onVideoFrameAvailable = { pixelBuffer, exposureTime in
            if !isSimMode {
                stackingEngine.processVideoFrame(pixelBuffer, exposureTime: exposureTime)
            }
        }
    }

    private func startPlanetCalculations() {
        updatePlanets()
        planetTimer?.invalidate()
        planetTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updatePlanets()
        }
    }

    private func stopPlanetCalculations() {
        planetTimer?.invalidate()
        planetTimer = nil
    }

    private func updatePlanets() {
        let loc = locationManager.currentLocation
        let list = SolarSystemEngine.calculateAllBodies(
            latitude: loc.latitude,
            longitude: loc.longitude
        )
        DispatchQueue.main.async {
            self.currentPlanets = list
        }
    }

    private func startSkySimulation() {
        simTimer?.invalidate()
        simTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if let frame = skySim.generateNextFrame() {
                DispatchQueue.main.async {
                    self.simulatedSkyImage = frame
                    self.stackingEngine.processBitmap(frame, exposureTime: self.cameraManager.state.exposureTimeSeconds)
                }
            }
        }
    }

    private func stopSkySimulation() {
        simTimer?.invalidate()
        simTimer = nil
        simulatedSkyImage = nil
    }
}

/// Helper bọc UIImage để hỗ trợ SwiftUI .sheet(item:)
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
