import SwiftUI

/// Bảng điều khiển các thông số thiên văn và phơi sáng chuyên nghiệp
/// Tái tạo chính xác 100% giao diện và tính năng của AstroControlPanel.kt trên Android
struct AstroControlPanel: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var stackingEngine: AstroStackingEngine
    @Binding var isSimMode: Bool
    var isRedMode: Bool

    @State private var activeTab: String? = "EXPOSURE" // "EXPOSURE", "ISO", "FRAMES", "STRETCH", nil
    @State private var isPanelCollapsed: Bool = false
    @State private var dragAccum: CGFloat = 0

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.165, blue: 0.294) : Color(red: 0.0, green: 0.898, blue: 1.0)
    }

    var panelBg: Color {
        isRedMode ? Color(red: 24/255.0, green: 4/255.0, blue: 7/255.0, opacity: 0.96)
                  : Color(red: 11/255.0, green: 16/255.0, blue: 29/255.0, opacity: 0.93)
    }

    var chipBg: Color {
        isRedMode ? Color.red.opacity(0.2) : Color(white: 0.15).opacity(0.4)
    }

    var chipBorder: Color {
        isRedMode ? Color.red.opacity(0.4) : Color(red: 0.0, green: 0.898, blue: 1.0).opacity(0.25)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Thanh Grip Indicator (Kéo xuống để thu gọn, kéo lên để mở ra, hoặc chạm vào để bật/tắt)
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.4))
                    .frame(width: 42, height: 4)
                Spacer()
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragAccum = value.translation.height
                    }
                    .onEnded { value in
                        if value.translation.height > 30 {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                isPanelCollapsed = true
                            }
                        } else if value.translation.height < -30 {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                isPanelCollapsed = false
                            }
                        }
                        dragAccum = 0
                    }
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isPanelCollapsed.toggle()
                }
            }

            // Nội dung panel
            if !isPanelCollapsed {
                VStack(spacing: 10) {
                    // 1. Hàng Mode Selector Pills (Ngân Hà, Khử Vệ Tinh, Vệt Sao, Thử Nghiệm Trời Ảo)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([
                                (StackingMode.deepSkyAverage, "🌌 Ngân Hà"),
                                (StackingMode.kappaSigma, "🛰️ Khử Vệ Tinh"),
                                (StackingMode.starTrails, "🌠 Vệt Sao")
                            ], id: \.0) { mode, label in
                                let isSelected = (!isSimMode && stackingEngine.selectedMode == mode)
                                Button(action: {
                                    guard !stackingEngine.isStacking else { return }
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    isSimMode = false
                                    stackingEngine.selectedMode = mode
                                }) {
                                    Text(label)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .black : .white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(isSelected ? accentColor : chipBg)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(isSelected ? accentColor : chipBorder, lineWidth: 1)
                                        )
                                }
                                .disabled(stackingEngine.isStacking)
                            }

                            // Sim / Demo Mode Pill
                            Button(action: {
                                guard !stackingEngine.isStacking else { return }
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                withAnimation {
                                    isSimMode.toggle()
                                }
                            }) {
                                Text("🧪 Thử Nghiệm Trời Ảo")
                                    .font(.system(size: 12, weight: isSimMode ? .bold : .medium))
                                    .foregroundColor(isSimMode ? .black : (isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.5) : Color(red: 1.0, green: 0.88, blue: 0.51)))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(isSimMode ? (isRedMode ? Color(red: 1.0, green: 0.32, blue: 0.32) : Color.yellow) : chipBg)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(isSimMode ? Color.yellow : chipBorder, lineWidth: 1)
                                    )
                            }
                            .disabled(stackingEngine.isStacking)
                        }
                        .padding(.horizontal, 2)
                    }

                    // 2. Thanh tham số chính: FOCUS | PHƠI SÁNG | ISO | SỐ FRAME | KÉO SÁNG
                    HStack(spacing: 6) {
                        // Nút Focus vô cực
                        Button(action: {
                            guard !stackingEngine.isStacking else { return }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            cameraManager.setInfinityFocusLock(!cameraManager.state.isInfinityLocked)
                        }) {
                            VStack(spacing: 2) {
                                Text("FOCUS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(cameraManager.state.isInfinityLocked ? .black : .gray)
                                Text(cameraManager.state.isInfinityLocked ? "∞ Vô cực" : "AF Auto")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(cameraManager.state.isInfinityLocked ? .black : .white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(cameraManager.state.isInfinityLocked ? accentColor : chipBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(cameraManager.state.isInfinityLocked ? accentColor : chipBorder, lineWidth: 1)
                            )
                        }
                        .disabled(stackingEngine.isStacking)

                        // Nút Phơi Sáng
                        Button(action: {
                            guard !stackingEngine.isStacking else { return }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTab = (activeTab == "EXPOSURE") ? nil : "EXPOSURE"
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text("PHƠI SÁNG")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("\(Int(cameraManager.state.exposureTimeSeconds))s")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(accentColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(activeTab == "EXPOSURE" ? accentColor.opacity(0.2) : chipBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(activeTab == "EXPOSURE" ? accentColor : chipBorder, lineWidth: 1)
                            )
                        }
                        .disabled(stackingEngine.isStacking)

                        // Nút ISO
                        Button(action: {
                            guard !stackingEngine.isStacking else { return }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTab = (activeTab == "ISO") ? nil : "ISO"
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text("ISO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("\(cameraManager.state.iso)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(activeTab == "ISO" ? accentColor.opacity(0.2) : chipBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(activeTab == "ISO" ? accentColor : chipBorder, lineWidth: 1)
                            )
                        }
                        .disabled(stackingEngine.isStacking)

                        // Nút Số Frame
                        Button(action: {
                            guard !stackingEngine.isStacking else { return }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTab = (activeTab == "FRAMES") ? nil : "FRAMES"
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text("SỐ FRAME")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("\(stackingEngine.targetFrames)x")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(activeTab == "FRAMES" ? accentColor.opacity(0.2) : chipBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(activeTab == "FRAMES" ? accentColor : chipBorder, lineWidth: 1)
                            )
                        }
                        .disabled(stackingEngine.isStacking)

                        // Nút Kéo Sáng (Stretch)
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTab = (activeTab == "STRETCH") ? nil : "STRETCH"
                            }
                        }) {
                            Text("⚙️ Kéo Sáng")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(activeTab == "STRETCH" ? .black : accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(activeTab == "STRETCH" ? accentColor : chipBg)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(activeTab == "STRETCH" ? accentColor : chipBorder, lineWidth: 1)
                                )
                        }
                    }

                    // 3. Khay tham số mở rộng (Sub-drawer)
                    if let tab = activeTab {
                        VStack(alignment: .leading, spacing: 6) {
                            switch tab {
                            case "EXPOSURE":
                                Text("Tốc độ màn trập (Thời gian phơi sáng mỗi frame)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([0.5, 1.0, 2.0, 4.0, 8.0, 15.0, 30.0], id: \.self) { sec in
                                            let isSelected = (cameraManager.state.exposureTimeSeconds == Float(sec))
                                            Button(action: {
                                                cameraManager.setExposureTime(Float(sec))
                                            }) {
                                                Text("\(Int(sec))s")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(isSelected ? .black : .white)
                                                    .frame(width: 52, height: 34)
                                                    .background(isSelected ? accentColor : Color.clear)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(accentColor, lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                }

                            case "ISO":
                                Text("Độ nhạy sáng cảm biến (ISO cao để bắt chi tiết tinh vân)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([400, 800, 1600, 3200, 6400, 12800], id: \.self) { val in
                                            let isSelected = (cameraManager.state.iso == val)
                                            Button(action: {
                                                cameraManager.setIso(val)
                                            }) {
                                                Text("\(val)")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(isSelected ? .black : .white)
                                                    .frame(width: 58, height: 34)
                                                    .background(isSelected ? accentColor : Color.clear)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(accentColor, lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                }

                            case "FRAMES":
                                Text("Mục tiêu số lượng ảnh xếp chồng (Càng nhiều frame càng khử nhiễu tốt)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([10, 20, 30, 50, 100], id: \.self) { count in
                                            let isSelected = (stackingEngine.targetFrames == count)
                                            Button(action: {
                                                stackingEngine.targetFrames = count
                                            }) {
                                                Text("\(count)x")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(isSelected ? .black : .white)
                                                    .frame(width: 54, height: 34)
                                                    .background(isSelected ? accentColor : Color.clear)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(accentColor, lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                }

                            case "STRETCH":
                                VStack(spacing: 6) {
                                    HStack {
                                        Text(String(format: "✨ Kéo sáng Tinh Vân (Midtone): %.2f", stackingEngine.midtoneStretch))
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    Slider(value: $stackingEngine.midtoneStretch, in: 0.02...0.50)
                                        .tint(accentColor)

                                    HStack {
                                        Text(String(format: "🌑 Khử ô nhiễm ánh sáng (Black Point): %.3f", stackingEngine.blackPoint))
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    Slider(value: $stackingEngine.blackPoint, in: 0.00...0.15)
                                        .tint(accentColor)
                                }

                            default:
                                EmptyView()
                            }
                        }
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(panelBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(chipBorder.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
    }
}
