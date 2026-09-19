import SwiftUI

/// Lớp phủ Thước thủy cân bằng điện tử & Phương vị la bàn (Artificial Horizon Leveler & Compass Reticle)
struct HorizonLevelerOverlay: View {
    @ObservedObject var motionManager: MotionSensorManager
    var isRedMode: Bool

    var lineColor: Color {
        if motionManager.isLevel {
            return Color.green
        }
        return isRedMode ? Color(red: 1.0, green: 0.2, blue: 0.2) : Color(red: 0.0, green: 0.9, blue: 1.0)
    }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let center = CGPoint(x: w / 2, y: h / 2)

            ZStack {
                // 1. Vòng ngắm trung tâm (Center Reticle)
                Circle()
                    .stroke(lineColor.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                    .position(center)

                Circle()
                    .fill(lineColor)
                    .frame(width: 4, height: 4)
                    .position(center)

                // 2. Đường chân trời xoay theo góc Roll (Artificial Horizon Line)
                Path { path in
                    path.move(to: CGPoint(x: center.x - 90, y: center.y))
                    path.addLine(to: CGPoint(x: center.x - 30, y: center.y))

                    path.move(to: CGPoint(x: center.x + 30, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + 90, y: center.y))
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-motionManager.rollDegrees), anchor: .center)
                .position(center)

                // 3. Hiển thị thông số góc nghiêng & La bàn
                VStack(spacing: 2) {
                    Text(String(format: "%.1f°", motionManager.rollDegrees))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(lineColor)

                    Text(String(format: "Pitch: %.1f° | Hdg: %03.0f°", motionManager.pitchDegrees, max(0, motionManager.yawDegrees)))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.4))
                .cornerRadius(6)
                .position(x: center.x, y: center.y + 60)
            }
        }
        .allowsHitTesting(false)
    }
}
