import SwiftUI

/// Hộp thoại xem chi tiết thông số thiên văn và kích hoạt dẫn đường mục tiêu cho hành tinh
/// Tương thích 100% với PlanetDetailDialog.kt trên Android
struct PlanetDetailDialog: View {
    let planet: PlanetInfo
    let isTargeted: Bool
    let isRedMode: Bool
    let onTargetToggle: (PlanetInfo) -> Void
    let onDismiss: () -> Void

    var dialogBg: Color {
        isRedMode ? Color(red: 24/255.0, green: 3/255.0, blue: 6/255.0, opacity: 0.98)
                  : Color(red: 11/255.0, green: 17/255.0, blue: 32/255.0, opacity: 0.98)
    }

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.165, blue: 0.294) : Color(red: 0.0, green: 0.898, blue: 1.0)
    }

    var cardBg: Color {
        isRedMode ? Color.red.opacity(0.12) : Color(red: 30/255.0, green: 41/255.0, blue: 59/255.0, opacity: 0.45)
    }

    var borderColor: Color {
        isRedMode ? Color.red.opacity(0.4) : Color(red: 56/255.0, green: 189/255.0, blue: 248/255.0, opacity: 0.3)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .center, spacing: 12) {
                        // 1. Biểu tượng hành tinh lớn ở đỉnh
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [planet.color.opacity(0.8), planet.glowColor.opacity(0.3), .clear]),
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 32
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .overlay(Circle().stroke(planet.color.opacity(0.8), lineWidth: 1.5))

                            Text(planet.symbol)
                                .font(.system(size: 32))
                        }
                        .padding(.top, 4)

                        // 2. Tên tiếng Việt & Tên tiếng Anh + Chòm sao
                        VStack(spacing: 3) {
                            Text(planet.nameVi)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.62) : .white)

                            Text("\(planet.nameEn) • Chòm sao: \(planet.constellationVi) \(planet.constellationSymbol)")
                                .font(.system(size: 12))
                                .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.62).opacity(0.8) : Color(red: 148/255.0, green: 163/255.0, blue: 184/255.0))
                        }

                        // 3. Huy hiệu Đang trên / Dưới chân trời
                        HStack(spacing: 5) {
                            Circle()
                                .fill(planet.isAboveHorizon ? (isRedMode ? Color.red : Color(red: 16/255.0, green: 185/255.0, blue: 129/255.0)) : Color.gray)
                                .frame(width: 8, height: 8)

                            Text(planet.isAboveHorizon ? "Đang trên bầu trời (Có thể quan sát)" : "Dưới đường chân trời (Không nhìn thấy)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(planet.isAboveHorizon ? (isRedMode ? Color.red : Color(red: 52/255.0, green: 211/255.0, blue: 153/255.0)) : .gray)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(planet.isAboveHorizon ? (isRedMode ? Color.red.opacity(0.2) : Color.green.opacity(0.15)) : Color(white: 0.2).opacity(0.3))
                        .cornerRadius(12)

                        // 4. Lưới thông số tọa độ thời gian thực
                        VStack(spacing: 8) {
                            coordRow(title: "Góc ngẩng (Altitude):", value: planet.formattedAltitude)
                            coordRow(title: "Phương vị (Azimuth):", value: planet.formattedAzimuth)
                            coordRow(title: "Khoảng cách tới Trái Đất:", value: planet.formattedDistance)
                            coordRow(title: "Độ sáng biểu kiến (Mag):", value: String(format: "%+.1f mag", planet.magnitude))

                            coordRow(title: "Đường kính thiên thể:", value: planet.formattedDiameter)
                        }
                        .padding(12)
                        .background(cardBg)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(borderColor, lineWidth: 1.0)
                        )

                        // 5. Giới thiệu khoa học
                        VStack(alignment: .leading, spacing: 4) {
                            Text("📖 Giới thiệu khoa học")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(accentColor)
                            Text(planet.descriptionVi)
                                .font(.system(size: 11))
                                .lineSpacing(3)
                                .foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // 6. Mẹo quan sát thiên văn
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🔭 Mẹo quan sát thiên văn")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.72, blue: 0.3) : Color(red: 1.0, green: 0.84, blue: 0.31))
                            Text(planet.observationTipVi)
                                .font(.system(size: 11))
                                .lineSpacing(3)
                                .foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // 7. Nút thao tác
                        HStack(spacing: 10) {
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                onTargetToggle(planet)
                                onDismiss()
                            }) {
                                Text(isTargeted ? "✕ Bỏ dẫn đường" : "🎯 Dẫn đường mục tiêu")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(isTargeted ? .white : .black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isTargeted ? (isRedMode ? Color(red: 107/255.0, green: 17/255.0, blue: 26/255.0) : Color(red: 15/255.0, green: 118/255.0, blue: 110/255.0)) : accentColor)
                                    .cornerRadius(14)
                            }

                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                onDismiss()
                            }) {
                                Text("Đóng")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(borderColor, lineWidth: 1.0)
                                    )
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
            .frame(maxWidth: 360)
            .frame(maxHeight: 560)
            .background(dialogBg)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(borderColor, lineWidth: 1.2)
            )
            .padding(.horizontal, 20)
        }
    }

    private func coordRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
