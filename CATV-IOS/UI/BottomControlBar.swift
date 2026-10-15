import SwiftUI

/// Thanh điều khiển phía đáy màn hình chứa nút chụp/quay thông minh biến đổi theo từng chế độ
/// Tương thích 100% với giao diện Bottom Shutter Bar của AstroAppScreen trên Android
struct BottomControlBar: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var stackingEngine: AstroStackingEngine
    var isRedMode: Bool

    var onShutterTapped: () -> Void
    var onThumbnailTapped: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.165, blue: 0.294) : Color(red: 0.0, green: 0.898, blue: 1.0)
    }

    var barBg: Color {
        isRedMode ? Color(red: 16/255.0, green: 2/255.0, blue: 4/255.0)
                  : Color(red: 8/255.0, green: 12/255.0, blue: 20/255.0, opacity: 0.93)
    }

    var body: some View {
        HStack(alignment: .center) {
            // 1. LEFT: Gallery Thumbnail / Quick Preview
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                onThumbnailTapped()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 54, height: 54)
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))

                    if let thumb = cameraManager.lastCapturedThumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                    } else {
                        Text("🖼️")
                            .font(.system(size: 22))
                    }
                }
            }
            .frame(width: 60)

            Spacer()

            // 2. CENTER: Mode-Adaptive Shutter Button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .heavy)
                impact.impactOccurred()
                onShutterTapped()
            }) {
                ZStack {
                    switch cameraManager.state.mode {
                    // --- PHOTO MODE ---
                    case .photo:
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 68, height: 68)
                        }

                    // --- VIDEO MODE ---
                    case .video:
                        let isRecording = cameraManager.state.isRecordingVideo
                        ZStack {
                            Circle()
                                .stroke(isRecording ? Color.red : Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)

                            if isRecording {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red)
                                    .frame(width: 32, height: 32)
                            } else {
                                Circle()
                                    .fill(Color(red: 229/255.0, green: 57/255.0, blue: 53/255.0))
                                    .frame(width: 68, height: 68)
                            }
                        }

                    // --- ASTRO MODE ---
                    case .astro:
                        let isCapturing = stackingEngine.isStacking
                        ZStack {
                            if isCapturing {
                                // Vòng phát sáng xung quanh với hiệu ứng nhịp thở
                                Circle()
                                    .fill(accentColor.opacity(0.35))
                                    .frame(width: 92, height: 92)
                                    .scaleEffect(pulseScale)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                            pulseScale = 1.15
                                        }
                                    }

                                // Vòng tiến trình tròn
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                    .frame(width: 90, height: 90)

                                Circle()
                                    .trim(from: 0, to: CGFloat(stackingEngine.stackedFrames) / CGFloat(max(1, stackingEngine.targetFrames)))
                                    .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 90, height: 90)
                                    .rotationEffect(.degrees(-90))
                            }

                            // Vòng tròn trung tâm
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: isCapturing
                                            ? [Color(red: 1.0, green: 0.2, blue: 0.29), Color(red: 0.72, green: 0.11, blue: 0.11)]
                                            : [accentColor, isRedMode ? Color(red: 0.72, green: 0.11, blue: 0.11) : Color(red: 0.0, green: 0.45, blue: 1.0)]
                                        ),
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 38
                                    )
                                )
                                .frame(width: 76, height: 76)
                                .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 3))

                            if isCapturing {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                            } else {
                                Text("✦")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                    // --- PRO MODE ---
                    case .pro:
                        ZStack {
                            Circle()
                                .stroke(Color(red: 1.0, green: 0.7, blue: 0.0), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            Circle()
                                .fill(Color(red: 1.0, green: 0.835, blue: 0.31))
                                .frame(width: 68, height: 68)
                            Text("PRO")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }
            }

            Spacer()

            // 3. RIGHT: Camera Switcher (Flip Front/Back)
            Button(action: {
                guard !stackingEngine.isStacking && !cameraManager.state.isRecordingVideo else { return }
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                cameraManager.switchCamera()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 54, height: 54)
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))

                    Text("🔄")
                        .font(.system(size: 22))
                }
            }
            .frame(width: 60)
            .disabled(stackingEngine.isStacking || cameraManager.state.isRecordingVideo)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(barBg)
    }
}
