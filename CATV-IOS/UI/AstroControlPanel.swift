import SwiftUI

/// Bảng điều khiển các thông số thiên văn và phơi sáng chuyên nghiệp (Astro / Pro Control Panel)
struct AstroControlPanel: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var stackingEngine: AstroStackingEngine
    var isRedMode: Bool

    @State private var isExpanded: Bool = true

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.16, blue: 0.29) : Color(red: 0.0, green: 0.9, blue: 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thanh tiêu đề rút gọn / mở rộng
            HStack {
                Label("THIẾT LẬP THIÊN VĂN & PHƠI SÁNG", systemImage: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(accentColor)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            if isExpanded {
                VStack(spacing: 12) {
                    // 1. Chọn chế độ xếp chồng
                    if cameraManager.state.mode == .astro {
                        Picker("Chế độ", selection: Binding(
                            get: { stackingEngine.stackingMode },
                            set: { stackingEngine.stackingMode = $0 }
                        )) {
                            ForEach(StackingMode.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // 2. ISO Slider
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("ISO")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(cameraManager.state.iso))")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(accentColor)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(cameraManager.state.iso) },
                                set: { cameraManager.setManualExposure(iso: Float($0), duration: cameraManager.state.exposureDurationSeconds) }
                            ),
                            in: Double(cameraManager.state.minIso)...Double(cameraManager.state.maxIso),
                            step: 50
                        )
                        .tint(accentColor)
                    }

                    // 3. Tốc độ màn trập (Exposure Duration)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Thời gian phơi sáng")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(String(format: "%.3fs", cameraManager.state.exposureDurationSeconds))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(accentColor)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(cameraManager.state.exposureDurationSeconds) },
                                set: { cameraManager.setManualExposure(iso: cameraManager.state.iso, duration: Float($0)) }
                            ),
                            in: Double(cameraManager.state.minExposureSeconds)...Double(cameraManager.state.maxExposureSeconds)
                        )
                        .tint(accentColor)
                    }

                    // 4. Kéo dãn MTF Stretch (Dành cho thiên văn)
                    if cameraManager.state.mode == .astro {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Độ giãn ảnh MTF (Midtone Stretch)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(String(format: "%.2f", stackingEngine.midtoneStretch))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(accentColor)
                            }
                            Slider(value: $stackingEngine.midtoneStretch, in: 0.05...0.6, step: 0.01)
                                .tint(accentColor)
                        }

                        // Số khung mục tiêu & Sao phát hiện
                        HStack {
                            Text("Mục tiêu: \(stackingEngine.targetFrames) frames")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("⭐ Đã phát hiện: \(stackingEngine.detectedStarCount) sao")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
    }
}
