import SwiftUI

/// Biểu đồ sắc độ Histogram thời gian thực
struct HistogramView: View {
    let histogramData: [Float]
    var isRedMode: Bool

    var curveColor: Color {
        isRedMode ? Color.red : Color(red: 0.0, green: 0.9, blue: 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("HISTOGRAM")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.7))

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Path { path in
                    guard histogramData.count > 1 else { return }
                    let step = w / CGFloat(histogramData.count - 1)

                    path.move(to: CGPoint(x: 0, y: h))

                    for (index, val) in histogramData.enumerated() {
                        let x = CGFloat(index) * step
                        let y = h - CGFloat(min(1.0, max(0.0, val))) * h
                        if index == 0 {
                            path.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [curveColor.opacity(0.6), curveColor.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    guard histogramData.count > 1 else { return }
                    let step = w / CGFloat(histogramData.count - 1)

                    for (index, val) in histogramData.enumerated() {
                        let x = CGFloat(index) * step
                        let y = h - CGFloat(min(1.0, max(0.0, val))) * h
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(curveColor, lineWidth: 1.5)
            }
        }
        .padding(8)
        .frame(width: 140, height: 75)
        .background(Color.black.opacity(0.6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
