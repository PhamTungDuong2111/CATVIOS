import SwiftUI

/// Cấu trúc lưu vị trí chiếu 3D của hành tinh lên màn hình camera
struct ProjectedPlanet: Identifiable {
    var id: String { planet.id }
    let planet: PlanetInfo
    let screenX: CGFloat
    let screenY: CGFloat
    let isOnScreen: Bool
    let isFront: Bool
    let edgeX: CGFloat
    let edgeY: CGFloat
    let edgeAngleDeg: Double
    let angularDistanceDeg: Double
}

/// Lớp phủ Thực tế Tăng cường (AR Solar System Planetary Overlay)
/// Chiếu vị trí các hành tinh trong Hệ Mặt Trời lên màn hình camera thời gian thực
/// Tương thích 100% với PlanetOverlay.kt trên Android
struct PlanetOverlay: View {
    let planets: [PlanetInfo]
    let orientation: OrientationData
    let isRedMode: Bool
    let selectedPlanet: PlanetInfo?
    let targetedPlanet: PlanetInfo?
    let onPlanetSelected: (PlanetInfo) -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var ringRotation: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            if w > 0 && h > 0 {
                let projectedList = computeProjectedPlanets(width: w, height: h)

                ZStack {
                    // 1. CANVAS: Đường Hoàng Đạo, Đĩa hành tinh & Vòng ngắm reticle
                    Canvas { context, size in
                        drawEclipticPath(context: context, size: size)

                        // Vẽ đồ họa cho các hành tinh đang trên màn hình
                        for item in projectedList where item.isOnScreen {
                            drawCelestialGraphic(
                                context: context,
                                item: item,
                                pulseScale: pulseScale,
                                ringRotation: ringRotation
                            )
                        }

                        // Vẽ vòng radar dẫn đường ở trung tâm khi mục tiêu đang ngoài màn hình
                        if let targeted = targetedPlanet,
                           let targetItem = projectedList.first(where: { $0.planet.id == targeted.id }),
                           !targetItem.isOnScreen {
                            drawTargetGuidanceRadar(context: context, size: size, targetItem: targetItem)
                        }
                    }
                    .allowsHitTesting(false)

                    // 2. CÁC THẺ BADGE TƯƠNG TÁC CHO HÀNH TINH TRÊN MÀN HÌNH
                    ForEach(projectedList.filter { $0.isOnScreen }) { item in
                        planetOnScreenBadge(item: item, width: w, height: h)
                    }

                    // 3. CÁC THẺ VIỀN CHỈ HƯỚNG NGOÀI MÀN HÌNH (Off-screen Directional Pills)
                    ForEach(projectedList.filter { !$0.isOnScreen && $0.planet.isAboveHorizon }) { item in
                        planetOffScreenPill(item: item, width: w, height: h)
                    }

                    // 4. BANNER DẪN ĐƯỜNG MỤC TIÊU Ở ĐÁY MÀN HÌNH (Target Guidance HUD Banner)
                    if let target = targetedPlanet,
                       let targetItem = projectedList.first(where: { $0.planet.id == target.id }) {
                        let isLocked = targetItem.isOnScreen && targetItem.angularDistanceDeg < 6.0
                        targetGuidanceBanner(target: target, targetItem: targetItem, isLocked: isLocked)
                            .padding(.bottom, 120)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
            withAnimation(.linear(duration: 16.0).repeatForever(autoreverses: false)) {
                ringRotation = 360.0
            }
        }
    }

    // MARK: - 3D Pinhole Projection

    private func computeProjectedPlanets(width: CGFloat, height: CGFloat) -> [ProjectedPlanet] {
        let rotMat = orientation.rotationMatrix
        let fovYDeg: Double = 60.0
        let fovYRad = fovYDeg * .pi / 180.0
        let focalPixels = (Double(height) / 2.0) / tan(fovYRad / 2.0)
        let centerX = Double(width) / 2.0
        let centerY = Double(height) / 2.0

        return planets.map { p in
            let altRad = Double(p.altitude) * .pi / 180.0
            let azRad = Double(p.azimuth) * .pi / 180.0

            let wx = cos(altRad) * sin(azRad)
            let wy = cos(altRad) * cos(azRad)
            let wz = sin(altRad)

            let dx = Double(rotMat[0]) * wx + Double(rotMat[3]) * wy + Double(rotMat[6]) * wz
            let dy = Double(rotMat[1]) * wx + Double(rotMat[4]) * wy + Double(rotMat[7]) * wz
            let dz = Double(rotMat[2]) * wx + Double(rotMat[5]) * wy + Double(rotMat[8]) * wz

            let zForward = -dz
            let isFront = zForward > 0.05
            let screenX: Double
            let screenY: Double
            let isOnScreen: Bool

            if isFront {
                screenX = centerX + focalPixels * (dx / zForward)
                screenY = centerY - focalPixels * (dy / zForward)
                isOnScreen = (screenX >= 40.0 && screenX <= Double(width) - 40.0 &&
                              screenY >= 60.0 && screenY <= Double(height) - 80.0)
            } else {
                let div = max(0.1, abs(zForward))
                screenX = centerX - focalPixels * (dx / div)
                screenY = centerY + focalPixels * (dy / div)
                isOnScreen = false
            }

            let dirX = isFront ? dx : -dx
            let dirY = isFront ? -dy : dy
            let len = max(0.001, sqrt(dirX * dirX + dirY * dirY))
            let ndx = dirX / len
            let ndy = dirY / len

            let edgeMarginX = 64.0
            let edgeMarginY = 110.0
            let halfW = (Double(width) / 2.0) - edgeMarginX
            let halfH = (Double(height) / 2.0) - edgeMarginY

            let scaleFactor = min(
                abs(ndx) > 1e-4 ? halfW / abs(ndx) : Double.infinity,
                abs(ndy) > 1e-4 ? halfH / abs(ndy) : Double.infinity
            )

            let edgeX = centerX + ndx * scaleFactor
            let edgeY = centerY + ndy * scaleFactor
            let edgeAngle = atan2(ndy, ndx) * 180.0 / .pi

            let cosAng = max(-1.0, min(1.0, zForward / max(0.001, sqrt(dx * dx + dy * dy + dz * dz))))
            let angularDist = acos(cosAng) * 180.0 / .pi

            return ProjectedPlanet(
                planet: p,
                screenX: CGFloat(screenX),
                screenY: CGFloat(screenY),
                isOnScreen: isOnScreen,
                isFront: isFront,
                edgeX: CGFloat(edgeX),
                edgeY: CGFloat(edgeY),
                edgeAngleDeg: edgeAngle,
                angularDistanceDeg: angularDist
            )
        }
    }

    // MARK: - Canvas Drawing Routines

    private func drawEclipticPath(context: GraphicsContext, size: CGSize) {
        let rotMat = orientation.rotationMatrix
        let fovYRad = 60.0 * .pi / 180.0
        let focalPixels = (Double(size.height) / 2.0) / tan(fovYRad / 2.0)
        let centerX = Double(size.width) / 2.0
        let centerY = Double(size.height) / 2.0

        let eclipticPoints = SolarSystemEngine.calculateEclipticPath(stepDeg: 6)
        let eclipticColor = isRedMode ? Color.red.opacity(0.3) : Color(red: 0.0, green: 0.898, blue: 1.0).opacity(0.25)

        var prevPoint: CGPoint? = nil

        for (eAlt, eAz) in eclipticPoints {
            let altRad = Double(eAlt) * .pi / 180.0
            let azRad = Double(eAz) * .pi / 180.0
            let wx = cos(altRad) * sin(azRad)
            let wy = cos(altRad) * cos(azRad)
            let wz = sin(altRad)

            let dx = Double(rotMat[0]) * wx + Double(rotMat[3]) * wy + Double(rotMat[6]) * wz
            let dy = Double(rotMat[1]) * wx + Double(rotMat[4]) * wy + Double(rotMat[7]) * wz
            let dz = Double(rotMat[2]) * wx + Double(rotMat[5]) * wy + Double(rotMat[8]) * wz

            if -dz > 0.1 {
                let zF = -dz
                let sx = centerX + focalPixels * (dx / zF)
                let sy = centerY - focalPixels * (dy / zF)
                let pt = CGPoint(x: sx, y: sy)

                if let prev = prevPoint, hypot(pt.x - prev.x, pt.y - prev.y) < 300 {
                    var path = Path()
                    path.move(to: prev)
                    path.addLine(to: pt)
                    context.stroke(
                        path,
                        with: .color(eclipticColor),
                        style: StrokeStyle(lineWidth: 1.8, dash: [10, 10])
                    )
                }
                prevPoint = pt
            } else {
                prevPoint = nil
            }
        }
    }

    private func drawCelestialGraphic(
        context: GraphicsContext,
        item: ProjectedPlanet,
        pulseScale: CGFloat,
        ringRotation: Double
    ) {
        let p = item.planet
        let isTargeted = targetedPlanet?.id == p.id
        let center = CGPoint(x: item.screenX, y: item.screenY)
        let baseColor = isRedMode ? Color.red : p.color
        let glowColor = isRedMode ? Color(red: 1.0, green: 0.1, blue: 0.27) : p.glowColor
        let radius: CGFloat = isTargeted ? 26.0 * pulseScale : 20.0

        // 1. Glowing Aura (Vầng sáng phát quang)
        let auraRect = CGRect(x: center.x - radius * 2.8, y: center.y - radius * 2.8, width: radius * 5.6, height: radius * 5.6)
        context.fill(
            Path(ellipseIn: auraRect),
            with: .radialGradient(
                Gradient(colors: [glowColor.opacity(0.45), .clear]),
                center: center,
                startRadius: 0,
                endRadius: radius * 2.8
            )
        )

        // 2. Planetary Body Disc (Đĩa hành tinh chi tiết)
        drawPlanetDisc(context: context, planet: p, center: center, radius: radius, baseColor: baseColor)

        // 3. Vòng tròn ngắm Reticle nét đứt xoay (Rotating Dashed Ring)
        let ringRadius = radius * 1.55
        let ringRect = CGRect(x: center.x - ringRadius, y: center.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2)
        let ringColor = isTargeted ? (isRedMode ? Color.red : Color(red: 0.0, green: 0.898, blue: 1.0)) : baseColor.opacity(0.6)

        var ringPath = Path(ellipseIn: ringRect)
        context.stroke(
            ringPath,
            with: .color(ringColor),
            style: StrokeStyle(lineWidth: isTargeted ? 2.5 : 1.2, dash: [6, 6], dashPhase: CGFloat(ringRotation))
        )

        // 4. Tick marks 4 góc chữ thập
        let r1 = radius * 1.7
        let r2 = r1 + 6.0
        var tickPath = Path()
        tickPath.move(to: CGPoint(x: center.x, y: center.y - r1))
        tickPath.addLine(to: CGPoint(x: center.x, y: center.y - r2))
        tickPath.move(to: CGPoint(x: center.x, y: center.y + r1))
        tickPath.addLine(to: CGPoint(x: center.x, y: center.y + r2))
        tickPath.move(to: CGPoint(x: center.x - r1, y: center.y))
        tickPath.addLine(to: CGPoint(x: center.x - r2, y: center.y))
        tickPath.move(to: CGPoint(x: center.x + r1, y: center.y))
        tickPath.addLine(to: CGPoint(x: center.x + r2, y: center.y))
        context.stroke(tickPath, with: .color(ringColor), style: StrokeStyle(lineWidth: 1.5))
    }

    private func drawPlanetDisc(
        context: GraphicsContext,
        planet: PlanetInfo,
        center: CGPoint,
        radius: CGFloat,
        baseColor: Color
    ) {
        let discRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        switch planet.id {
        case "SATURN":
            // Vành đai Sao Thổ nghiêng (Tilted elliptical ring)
            let ringW = radius * 2.8
            let ringH = radius * 0.95
            let ringRect = CGRect(x: center.x - ringW / 2, y: center.y - ringH / 2, width: ringW, height: ringH)
            context.stroke(
                Path(ellipseIn: ringRect),
                with: .color(Color(red: 1.0, green: 0.88, blue: 0.51).opacity(0.85)),
                style: StrokeStyle(lineWidth: 3.5)
            )
            // Khối cầu Sao Thổ
            context.fill(
                Path(ellipseIn: discRect),
                with: .radialGradient(
                    Gradient(colors: [baseColor, Color(red: 0.71, green: 0.56, blue: 0.16)]),
                    center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.3),
                    startRadius: 0,
                    endRadius: radius
                )
            )

        case "JUPITER":
            // Sao Mộc với 2 dải mây khí quyển
            context.fill(Path(ellipseIn: discRect), with: .color(baseColor))
            let stripeH = radius * 0.25
            let stripe1 = CGRect(x: center.x - radius * 0.85, y: center.y - stripeH * 1.5, width: radius * 1.7, height: stripeH)
            let stripe2 = CGRect(x: center.x - radius * 0.85, y: center.y + stripeH * 0.5, width: radius * 1.7, height: stripeH)
            context.fill(Path(stripe1), with: .color(Color(red: 0.72, green: 0.42, blue: 0.11).opacity(0.6)))
            context.fill(Path(stripe2), with: .color(Color(red: 0.72, green: 0.42, blue: 0.11).opacity(0.6)))

        case "MARS":
            // Sao Hỏa đỏ rỉ sét với gradient
            context.fill(
                Path(ellipseIn: discRect),
                with: .radialGradient(
                    Gradient(colors: [Color(red: 1.0, green: 0.54, blue: 0.4), baseColor, Color(red: 0.75, green: 0.21, blue: 0.05)]),
                    center: CGPoint(x: center.x - radius * 0.2, y: center.y - radius * 0.2),
                    startRadius: 0,
                    endRadius: radius
                )
            )

        case "VENUS":
            // Sao Kim lấp lánh rực rỡ với tia lóe sáng 4 hướng
            context.fill(
                Path(ellipseIn: discRect),
                with: .radialGradient(
                    Gradient(colors: [.white, Color(red: 1.0, green: 0.98, blue: 0.77), baseColor]),
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            let flareLen = radius * 2.2
            var flarePath = Path()
            flarePath.move(to: CGPoint(x: center.x - flareLen, y: center.y))
            flarePath.addLine(to: CGPoint(x: center.x + flareLen, y: center.y))
            flarePath.move(to: CGPoint(x: center.x, y: center.y - flareLen))
            flarePath.addLine(to: CGPoint(x: center.x, y: center.y + flareLen))
            context.stroke(flarePath, with: .color(Color.white.opacity(0.8)), style: StrokeStyle(lineWidth: 1.2))

        case "MOON":
            // Mặt Trăng với bề mặt xám nhạt và các hố va chạm
            context.fill(Path(ellipseIn: discRect), with: .color(Color(red: 236/255.0, green: 239/255.0, blue: 241/255.0)))
            let crater1 = CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.2, width: radius * 0.6, height: radius * 0.6)
            let crater2 = CGRect(x: center.x + radius * 0.1, y: center.y + radius * 0.2, width: radius * 0.4, height: radius * 0.4)
            context.fill(Path(ellipseIn: crater1), with: .color(Color(red: 120/255.0, green: 144/255.0, blue: 156/255.0).opacity(0.35)))
            context.fill(Path(ellipseIn: crater2), with: .color(Color(red: 120/255.0, green: 144/255.0, blue: 156/255.0).opacity(0.35)))

        case "SUN":
            // Mặt Trời với quầng hào quang corona
            context.fill(
                Path(ellipseIn: discRect),
                with: .radialGradient(
                    Gradient(colors: [Color(red: 1.0, green: 0.99, blue: 0.9), Color(red: 1.0, green: 0.84, blue: 0.31), Color(red: 1.0, green: 0.56, blue: 0.0)]),
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
            )

        default:
            // Hành tinh tiêu chuẩn
            context.fill(
                Path(ellipseIn: discRect),
                with: .radialGradient(
                    Gradient(colors: [baseColor, baseColor.opacity(0.7)]),
                    center: CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.25),
                    startRadius: 0,
                    endRadius: radius
                )
            )
        }
    }

    private func drawTargetGuidanceRadar(context: GraphicsContext, size: CGSize, targetItem: ProjectedPlanet) {
        let cx = size.width / 2.0
        let cy = size.height / 2.0
        let center = CGPoint(x: cx, y: cy)
        let guideColor = isRedMode ? Color.red : Color(red: 0.0, green: 0.898, blue: 1.0)

        // Vòng tròn định vị radar tâm màn hình
        let radarRect = CGRect(x: cx - 75.0, y: cy - 75.0, width: 150.0, height: 150.0)
        context.stroke(
            Path(ellipseIn: radarRect),
            with: .color(guideColor.opacity(0.4)),
            style: StrokeStyle(lineWidth: 2.0, dash: [10, 10])
        )

        // Mũi tên từ tâm màn hình chỉ về phía hành tinh mục tiêu
        let rad = targetItem.edgeAngleDeg * .pi / 180.0
        let arrowLen: CGFloat = 65.0
        let ax = cx + CGFloat(cos(rad)) * arrowLen
        let ay = cy + CGFloat(sin(rad)) * arrowLen

        var arrowPath = Path()
        arrowPath.move(to: center)
        arrowPath.addLine(to: CGPoint(x: ax, y: ay))
        context.stroke(arrowPath, with: .color(guideColor), style: StrokeStyle(lineWidth: 3.0, lineCap: .round))

        let dotRect = CGRect(x: ax - 5.0, y: ay - 5.0, width: 10.0, height: 10.0)
        context.fill(Path(ellipseIn: dotRect), with: .color(guideColor))
    }

    // MARK: - Subviews: Interactive Badges

    private func planetOnScreenBadge(item: ProjectedPlanet, width: CGFloat, height: CGFloat) -> some View {
        let p = item.planet
        let isTargeted = targetedPlanet?.id == p.id
        let isSelected = selectedPlanet?.id == p.id
        let tagX = min(max(item.screenX + 24.0, 16.0), width - 210.0)
        let tagY = min(max(item.screenY + 24.0, 40.0), height - 110.0)

        let cardBg = isRedMode ? Color(red: 26/255.0, green: 2/255.0, blue: 5/255.0, opacity: 0.9)
                               : Color(red: 11/255.0, green: 18/255.0, blue: 32/255.0, opacity: 0.88)
        let borderColor = isTargeted ? (isRedMode ? Color.red : Color(red: 0.0, green: 0.898, blue: 1.0))
                                     : (isRedMode ? Color.red.opacity(0.4) : Color(red: 56/255.0, green: 189/255.0, blue: 248/255.0, opacity: 0.35))

        return Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onPlanetSelected(p)
        }) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(p.symbol)
                        .font(.system(size: 14))
                    Text(p.nameVi)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.62) : .white)
                    Text(p.constellationSymbol)
                        .font(.system(size: 11))
                        .foregroundColor(isRedMode ? Color.red.opacity(0.7) : Color(red: 56/255.0, green: 189/255.0, blue: 248/255.0))
                }

                Text("Alt: \(p.formattedAltitude)  Az: \(Int(p.azimuth))°")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.7, blue: 0.73) : Color(red: 176/255.0, green: 190/255.0, blue: 197/255.0))

                Text(String(format: "Mag: %+.1f • %@", p.magnitude, p.constellationVi))
                    .font(.system(size: 9))
                    .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.62).opacity(0.8) : Color(red: 148/255.0, green: 163/255.0, blue: 184/255.0))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(cardBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: (isTargeted || isSelected) ? 1.5 : 1.0)
            )
        }
        .buttonStyle(.plain)
        .position(x: tagX + 85.0, y: tagY + 28.0)
    }

    private func planetOffScreenPill(item: ProjectedPlanet, width: CGFloat, height: CGFloat) -> some View {
        let p = item.planet
        let isTargeted = targetedPlanet?.id == p.id
        let pillX = min(max(item.edgeX, 55.0), width - 55.0)
        let pillY = min(max(item.edgeY, 50.0), height - 70.0)

        let pillBg = isRedMode ? Color(red: 37/255.0, green: 5/255.0, blue: 10/255.0, opacity: 0.9)
                               : Color(red: 9/255.0, green: 17/255.0, blue: 34/255.0, opacity: 0.92)
        let pillBorder = isTargeted ? (isRedMode ? Color.red : Color(red: 0.0, green: 0.898, blue: 1.0))
                                    : (isRedMode ? Color.red.opacity(0.35) : Color(red: 56/255.0, green: 189/255.0, blue: 248/255.0, opacity: 0.25))

        return Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onPlanetSelected(p)
        }) {
            HStack(spacing: 4) {
                Text(p.symbol)
                    .font(.system(size: 12))
                Text(p.nameVi)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isRedMode ? Color(red: 1.0, green: 0.54, blue: 0.62) : .white)

                // Mũi tên xoay chỉ về hướng hành tinh ngoài màn hình
                Text("➤")
                    .font(.system(size: 10))
                    .rotationEffect(.degrees(item.edgeAngleDeg))
                    .foregroundColor(isTargeted ? (isRedMode ? .red : Color(red: 0.0, green: 0.898, blue: 1.0))
                                               : (isRedMode ? Color.red.opacity(0.8) : Color(red: 56/255.0, green: 189/255.0, blue: 248/255.0)))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(pillBg)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(pillBorder, lineWidth: isTargeted ? 1.5 : 1.0)
            )
        }
        .buttonStyle(.plain)
        .position(x: pillX, y: pillY)
    }

    private func targetGuidanceBanner(target: PlanetInfo, targetItem: ProjectedPlanet, isLocked: Bool) -> some View {
        let bannerBg = isLocked
            ? (isRedMode ? Color(red: 64/255.0, green: 6/255.0, blue: 12/255.0, opacity: 0.9) : Color(red: 6/255.0, green: 78/255.0, blue: 59/255.0, opacity: 0.9))
            : (isRedMode ? Color(red: 32/255.0, green: 3/255.0, blue: 7/255.0, opacity: 0.88) : Color(red: 15/255.0, green: 23/255.0, blue: 42/255.0, opacity: 0.88))

        let bannerBorder = isLocked
            ? (isRedMode ? Color.red : Color(red: 16/255.0, green: 185/255.0, blue: 129/255.0))
            : (isRedMode ? Color.red.opacity(0.4) : Color(red: 56/255.0, green: 189/255.0, blue: 248/255.0, opacity: 0.4))

        return HStack(spacing: 10) {
            Text(target.symbol)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(isLocked ? "🎯 ĐÃ KHÓA MỤC TIÊU: \(target.nameVi.uppercased())" : "🧭 HƯỚNG VỀ \(target.nameVi.uppercased())")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isLocked ? (isRedMode ? Color(red: 1.0, green: 0.32, blue: 0.32) : Color(red: 52/255.0, green: 211/255.0, blue: 153/255.0)) : .white)

                Text(isLocked ? "Độ cao: \(target.formattedAltitude) • Hướng: \(target.formattedAzimuth)" : "Lệch: \(Int(targetItem.angularDistanceDeg.rounded()))° • Xoay điện thoại theo mũi tên")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(bannerBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(bannerBorder, lineWidth: 1.0)
        )
    }
}
