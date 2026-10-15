import SwiftUI

/// Thanh công cụ phía trên kiểu kính mờ (Top HUD Glass Bar)
/// Tương thích 100% với giao diện TOP HUD BAR của AstroAppScreen trên Android
struct TopGlassBar: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var stackingEngine: AstroStackingEngine

    @Binding var showLeveler: Bool
    @Binding var showHistogram: Bool
    @Binding var isRedMode: Bool
    var isSimMode: Bool

    @State private var blinkAlpha: Double = 1.0

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.165, blue: 0.294) : Color(red: 0.0, green: 0.898, blue: 1.0)
    }

    var bgOverlay: Color {
        isRedMode ? Color(red: 21/255.0, green: 3/255.0, blue: 6/255.0, opacity: 0.8)
                  : Color(red: 7/255.0, green: 11/255.0, blue: 20/255.0, opacity: 0.7)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Thanh HUD chính dạng Glass Pill
            HStack(spacing: 8) {
                // Trái: Flash + Leveler + Red Mode
                HStack(spacing: 6) {
                    // Flash Toggle Button
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        cameraManager.toggleFlash()
                    }) {
                        Text(cameraManager.state.flashMode.icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(cameraManager.state.flashMode.color))
                            .frame(width: 36, height: 36)
                    }

                    // Leveler Toggle Button
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation {
                            showLeveler.toggle()
                        }
                    }) {
                        Text("📐")
                            .font(.system(size: 15))
                            .foregroundColor(showLeveler ? accentColor : .gray)
                            .frame(width: 36, height: 36)
                    }

                    // Red Night Mode Toggle
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isRedMode.toggle()
                        }
                    }) {
                        Text(isRedMode ? "🔴" : "⚪")
                            .font(.system(size: 14))
                            .frame(width: 36, height: 36)
                    }
                }

                Spacer()

                // Giữa: Huy hiệu trạng thái (Video Recording Timer / Stacking Progress / Mode Title)
                Group {
                    if cameraManager.state.isRecordingVideo {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .opacity(blinkAlpha)
                                .onAppear {
                                    withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: true)) {
                                        blinkAlpha = 0.2
                                    }
                                }

                            let mins = cameraManager.state.recordingDurationSeconds / 60
                            let secs = cameraManager.state.recordingDurationSeconds % 60
                            Text(String(format: "%02d:%02d", mins, secs))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 183/255.0, green: 28/255.0, blue: 28/255.0, opacity: 0.85))
                        .cornerRadius(12)
                    } else if stackingEngine.isStacking {
                        HStack(spacing: 4) {
                            Text("🌌 \(stackingEngine.stackedFrames)/\(stackingEngine.targetFrames) • \(Int(stackingEngine.totalExposureSeconds))s")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.25))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentColor, lineWidth: 1)
                        )
                    } else {
                        Text(cameraManager.state.mode.statusTitle)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }

                Spacer()

                // Phải: Nút mở Histogram
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showHistogram.toggle()
                    }
                }) {
                    Text("📊")
                        .font(.system(size: 15))
                        .foregroundColor(showHistogram ? accentColor : .gray)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(bgOverlay)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)

            // Dòng phụ hiển thị số sao nhận diện & số khung bị lọc trong chế độ THIÊN VĂN
            if cameraManager.state.mode == .astro {
                HStack {
                    HStack(spacing: 4) {
                        Text(isSimMode ? "🧪 Giả lập bầu trời" : "⭐ \(stackingEngine.detectedStarCount) sao nhận diện")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(stackingEngine.detectedStarCount >= 4 ? accentColor : .gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(bgOverlay)
                    .cornerRadius(14)

                    Spacer()

                    if stackingEngine.rejectedFrames > 0 {
                        HStack(spacing: 4) {
                            Text("⚠️ Đã lọc: \(stackingEngine.rejectedFrames)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.72, blue: 0.3))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 62/255.0, green: 39/255.0, blue: 35/255.0, opacity: 0.8))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
