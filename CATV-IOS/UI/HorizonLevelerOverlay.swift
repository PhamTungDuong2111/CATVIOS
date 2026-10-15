import SwiftUI

/// Lớp phủ Thước thủy điện tử, lưới bố cục 1/3 và phương vị la bàn
/// Tương thích 100% với LevelerOverlay.kt trên Android
struct HorizonLevelerOverlay: View {
    @ObservedObject var motionManager: MotionSensorManager
    var isRedMode: Bool
    var showGrid: Bool = true

    var levelColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.32, blue: 0.32) : Color(red: 0.0, green: 0.902, blue: 0.463) // #00E676
    }

    var tiltColor: Color {
        isRedMode ? Color.red.opacity(0.4) : Color.white.opacity(0.4)
    }

    var gridColor: Color {
        isRedMode ? Color.red.opacity(0.14) : Color.white.opacity(0.14)
    }

    var crossColor: Color {
        isRedMode ? Color.red.opacity(0.55) : Color(red: 0.0, green: 0.898, blue: 1.0).opacity(0.55)
    }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let cx = w / 2.0
            let cy = h / 2.0

            ZStack {
                // 1. Lưới quy tắc 1/3 (Rule-of-Thirds Grid)
                if showGrid {
                    Path { path in
                        // Đường dọc
                        path.move(to: CGPoint(x: w / 3.0, y: 0))
                        path.addLine(to: CGPoint(x: w / 3.0, y: h))

                        path.move(to: CGPoint(x: w * 2.0 / 3.0, y: 0))
                        path.addLine(to: CGPoint(x: w * 2.0 / 3.0, y: h))

                        // Đường ngang
                        path.move(to: CGPoint(x: 0, y: h / 3.0))
                        path.addLine(to: CGPoint(x: w, y: h / 3.0))

                        path.move(to: CGPoint(x: 0, y: h * 2.0 / 3.0))
                        path.addLine(to: CGPoint(x: w, y: h * 2.0 / 3.0))
                    }
                    .stroke(gridColor, lineWidth: 1.0)
                }

                // 2. Tâm ngắm chữ thập trung tâm (Center Crosshair)
                let crossSize: CGFloat = 16.0
                Path { path in
                    path.move(to: CGPoint(x: cx - crossSize, y: cy))
                    path.addLine(to: CGPoint(x: cx + crossSize, y: cy))

                    path.move(to: CGPoint(x: cx, y: cy - crossSize))
                    path.addLine(to: CGPoint(x: cx, y: cy + crossSize))
                }
                .stroke(crossColor, lineWidth: 1.5)

                // 3. Thước thủy chân trời (Horizon Leveler Bar xoay theo góc -roll)
                let barLength: CGFloat = 70.0
                let centerGap: CGFloat = 18.0
                let isLevel = motionManager.isLevel

                Path { path in
                    // Cánh trái
                    path.move(to: CGPoint(x: cx - barLength, y: cy))
                    path.addLine(to: CGPoint(x: cx - centerGap, y: cy))

                    // Cánh phải
                    path.move(to: CGPoint(x: cx + centerGap, y: cy))
                    path.addLine(to: CGPoint(x: cx + barLength, y: cy))
                }
                .stroke(isLevel ? levelColor : tiltColor, style: StrokeStyle(lineWidth: isLevel ? 3.5 : 2.0, lineCap: .round))
                .rotationEffect(.degrees(-motionManager.rollDegrees), anchor: .center)

                // 4. Dòng trạng thái la bàn, góc ngẩng và góc nghiêng ở đáy
                VStack {
                    Spacer()
                    Text(String(
                        format: "%@  |  Góc ngẩng: %+.1f°  |  Nghiêng: %+.1f° %@",
                        motionManager.orientation.cardinalDirection,
                        motionManager.pitchDegrees,
                        motionManager.rollDegrees,
                        isLevel ? "✓ CHUẨN" : ""
                    ))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isLevel ? levelColor : (isRedMode ? Color.red.opacity(0.8) : Color.white.opacity(0.8)))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(8)
                    .padding(.bottom, 12)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
