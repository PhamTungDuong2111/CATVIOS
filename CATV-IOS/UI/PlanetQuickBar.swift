import SwiftUI

/// Thanh tra cứu hành tinh nhanh cuộn ngang phía trên màn hình (Planet Quick Bar)
/// Tương thích 100% với PlanetQuickBar.kt trên Android
struct PlanetQuickBar: View {
    let planets: [PlanetInfo]
    let selectedPlanet: PlanetInfo?
    let targetedPlanet: PlanetInfo?
    let isRedMode: Bool
    let onPlanetSelected: (PlanetInfo) -> Void
    let onPlanetTargetToggle: (PlanetInfo) -> Void
    let onClose: () -> Void

    var barBg: Color {
        isRedMode ? Color(red: 28/255.0, green: 4/255.0, blue: 7/255.0, opacity: 0.95)
                  : Color(red: 9/255.0, green: 15/255.0, blue: 30/255.0, opacity: 0.93)
    }

    var barBorder: Color {
        isRedMode ? Color.red.opacity(0.4) : Color(red: 56/255.0, green: 189/255.0, blue: 248/255.0, opacity: 0.25)
    }

    var visibleCount: Int {
        planets.filter { $0.isAboveHorizon }.count
    }

    var sortedPlanets: [PlanetInfo] {
        planets.sorted { (p1, p2) -> Bool in
            if p1.isAboveHorizon != p2.isAboveHorizon {
                return p1.isAboveHorizon && !p2.isAboveHorizon
            }
            return p1.altitude > p2.altitude
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Hàng tiêu đề trên: Tên + Huy hiệu số lượng + Nút đóng ✕
            HStack {
                HStack(spacing: 6) {
                    Text("🪐")
                        .font(.system(size: 13))
                    Text("VỊ TRÍ CÁC HÀNH TINH")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.62) : .white)

                    Text("\(visibleCount)/\(planets.count) trên bầu trời")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isRedMode ? Color.red : Color(red: 52/255.0, green: 211/255.0, blue: 153/255.0))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isRedMode ? Color.red.opacity(0.2) : Color.green.opacity(0.15))
                        .cornerRadius(8)
                }

                Spacer()

                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onClose()
                }) {
                    Text("✕")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(4)
                }
            }
            .padding(.horizontal, 14)

            // Dãy chip hành tinh cuộn ngang
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sortedPlanets) { p in
                        let isTargeted = targetedPlanet?.id == p.id

                        let chipBg: Color = {
                            if isTargeted {
                                return isRedMode ? Color.red.opacity(0.27) : Color(red: 0.0, green: 0.898, blue: 1.0).opacity(0.2)
                            } else if p.isAboveHorizon {
                                return isRedMode ? Color.red.opacity(0.14) : Color(white: 0.15).opacity(0.3)
                            } else {
                                return Color(white: 0.08).opacity(0.3)
                            }
                        }()

                        let chipBorder: Color = {
                            if isTargeted {
                                return isRedMode ? Color.red : Color(red: 0.0, green: 0.898, blue: 1.0)
                            } else if p.isAboveHorizon {
                                return isRedMode ? Color.red.opacity(0.35) : Color(red: 56/255.0, green: 189/255.0, blue: 248/255.0).opacity(0.25)
                            } else {
                                return Color(white: 0.3).opacity(0.2)
                            }
                        }()

                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            if isTargeted {
                                onPlanetSelected(p)
                            } else {
                                onPlanetTargetToggle(p)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(p.symbol)
                                    .font(.system(size: 14))

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(p.nameVi)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.62) : (p.isAboveHorizon ? .white : .gray))

                                        Circle()
                                            .fill(p.isAboveHorizon ? (isRedMode ? Color.red : Color(red: 16/255.0, green: 185/255.0, blue: 129/255.0)) : Color(white: 0.4))
                                            .frame(width: 6, height: 6)
                                    }

                                    Text("\(p.formattedAltitude) • \(Int(p.azimuth))°")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.62).opacity(0.8) : (p.isAboveHorizon ? Color(red: 176/255.0, green: 190/255.0, blue: 197/255.0) : Color(white: 0.4)))
                                }

                                if isTargeted {
                                    Text("🎯")
                                        .font(.system(size: 11))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(chipBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(chipBorder, lineWidth: 1.0)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
        .background(barBg)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(barBorder, lineWidth: 1.0)
        )
    }
}
