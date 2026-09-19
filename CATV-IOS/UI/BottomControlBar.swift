import SwiftUI

/// Thanh điều khiển chụp/quay phía đáy màn hình (Bottom Control Bar)
struct BottomControlBar: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var stackingEngine: AstroStackingEngine
    var isRedMode: Bool

    var onShutterTapped: () -> Void
    var onThumbnailTapped: () -> Void

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.16, blue: 0.29) : Color(red: 0.0, green: 0.9, blue: 1.0)
    }

    var body: some View {
        HStack(alignment: .center) {
            // 1. LEFT: Vòng tròn xem trước ảnh/video vừa chụp
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onThumbnailTapped()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 54, height: 54)
                        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))

                    if let thumb = cameraManager.lastCapturedThumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(width: 60)

            Spacer()

            // 2. CENTER: Nút chụp / quay thông minh biến đổi theo từng chế độ
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                onShutterTapped()
            }) {
                ZStack {
                    switch cameraManager.state.mode {
                    // --- CHẾ ĐỘ CHỤP ẢNH (PHOTO) ---
                    case .photo:
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 78, height: 78)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 64, height: 64)

                    // --- CHẾ ĐỘ QUAY VIDEO (VIDEO) ---
                    case .video:
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 78, height: 78)

                        if cameraManager.state.isRecordingVideo {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: 32, height: 32)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 64, height: 64)
                        }

                    // --- CHẾ ĐỘ THIÊN VĂN (ASTRO) ---
                    case .astro:
                        ZStack {
                            Circle()
                                .stroke(accentColor.opacity(0.4), lineWidth: 4)
                                .frame(width: 80, height: 80)

                            if stackingEngine.isStacking {
                                // Vòng tiến trình xếp chồng
                                Circle()
                                    .trim(from: 0, to: CGFloat(stackingEngine.stackedFrames) / CGFloat(stackingEngine.targetFrames))
                                    .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                            }

                            Circle()
                                .fill(stackingEngine.isStacking ? Color.red : accentColor)
                                .frame(width: 64, height: 64)

                            Image(systemName: stackingEngine.isStacking ? "stop.fill" : "sparkles")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                        }

                    // --- CHẾ ĐỘ CHUYÊN NGHIỆP (PRO) ---
                    case .pro:
                        Circle()
                            .stroke(Color.yellow, lineWidth: 4)
                            .frame(width: 78, height: 78)
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text("PRO")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.black)
                            )
                    }
                }
            }

            Spacer()

            // 3. RIGHT: Nút lật camera trước / camera sau (Flip Camera)
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                cameraManager.switchCamera()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 54, height: 54)
                        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))

                    Image(systemName: "camera.rotate.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 60)
            .disabled(stackingEngine.isStacking || cameraManager.state.isRecordingVideo)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}
