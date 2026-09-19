import SwiftUI

/// Thanh công cụ phía trên kiểu kính mờ (Top Glass Bar)
struct TopGlassBar: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var stackingEngine: AstroStackingEngine

    @Binding var showLeveler: Bool
    @Binding var showHistogram: Bool
    @Binding var isRedMode: Bool

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.16, blue: 0.29) : Color(red: 0.0, green: 0.9, blue: 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            // 1. Nút Flash / Torch
            Button(action: {
                cameraManager.toggleFlash()
            }) {
                Image(systemName: cameraManager.state.flashMode.iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(cameraManager.state.flashMode == .off ? .white : .yellow)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }

            // 2. Nút bật/tắt Thước thủy (Leveler)
            Button(action: {
                showLeveler.toggle()
            }) {
                Image(systemName: "gyroscope")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(showLeveler ? accentColor : .white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(showLeveler ? accentColor.opacity(0.2) : Color.black.opacity(0.4))
                    .clipShape(Circle())
            }

            // 3. Nút bật/tắt Chế độ nhìn đêm (Red Mode)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isRedMode.toggle()
                }
            }) {
                Image(systemName: isRedMode ? "moon.fill" : "moon")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isRedMode ? Color.red : .white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(isRedMode ? Color.red.opacity(0.25) : Color.black.opacity(0.4))
                    .clipShape(Circle())
            }

            // 4. Nút bật/tắt Histogram
            Button(action: {
                showHistogram.toggle()
            }) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(showHistogram ? accentColor : .white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(showHistogram ? accentColor.opacity(0.2) : Color.black.opacity(0.4))
                    .clipShape(Circle())
            }

            Spacer()

            // 5. Huy hiệu trạng thái động (Đang quay video hoặc Đang xếp chồng sao)
            if cameraManager.state.isRecordingVideo {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text(timeString(from: cameraManager.state.recordingDurationSeconds))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .cornerRadius(12)
            } else if stackingEngine.isStacking {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor)
                    Text("\(stackingEngine.stackedFrames)/\(stackingEngine.targetFrames)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .cornerRadius(12)
            } else {
                Text(cameraManager.state.mode.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
    }

    private func timeString(from totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
