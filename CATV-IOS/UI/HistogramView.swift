import SwiftUI

/// Biểu đồ sắc độ Histogram chuẩn thiên văn với tỷ lệ Logarithmic
/// Tương thích 100% với AstroHistogramView.kt trên Android
struct HistogramView: View {
    let histogramData: [Int]?
    var isRedMode: Bool

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.165, blue: 0.294) : Color(red: 0.0, green: 0.898, blue: 1.0)
    }

    var fillColor: Color {
        isRedMode ? Color.red.opacity(0.4) : Color(red: 0.0, green: 0.69, blue: 1.0).opacity(0.35)
    }

    var borderColor: Color {
        isRedMode ? Color.red.opacity(0.3) : Color(red: 0.0, green: 0.898, blue: 1.0).opacity(0.2)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                if let data = histogramData, data.count > 1 {
                    let maxVal = max(1, data.max() ?? 1)
                    let bins = data.count
                    let step = w / CGFloat(bins - 1)

                    // Path tô màu vùng dưới (Fill Gradient Path)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))

                        for i in 0..<bins {
                            let x = CGFloat(i) * step
                            let normY = Double(data[i]) / Double(maxVal)
                            // Logarithmic dynamic range
                            let logY = log10(1.0 + normY * 9.0) / log10(10.0)
                            let y = h - CGFloat(logY) * (h - 4.0)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [fillColor, Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Đường cong viền (Stroke Path)
                    Path { path in
                        for i in 0..<bins {
                            let x = CGFloat(i) * step
                            let normY = Double(data[i]) / Double(maxVal)
                            let logY = log10(1.0 + normY * 9.0) / log10(10.0)
                            let y = h - CGFloat(logY) * (h - 4.0)

                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                } else {
                    // Đường chuẩn khi chưa có dữ liệu
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h * 0.5))
                        path.addLine(to: CGPoint(x: w, y: h * 0.5))
                    }
                    .stroke(borderColor, lineWidth: 1)
                }
            }
            .padding(4)

            // Mini HUD Label
            Text("HISTOGRAM")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(isRedMode ? Color.red.opacity(0.8) : Color(red: 0.0, green: 0.898, blue: 1.0).opacity(0.8))
                .padding(.leading, 6)
                .padding(.top, 4)
        }
        .frame(width: 140, height: 70)
        .background(Color(red: 10/255.0, green: 14/255.0, blue: 23/255.0, opacity: 0.8))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}
