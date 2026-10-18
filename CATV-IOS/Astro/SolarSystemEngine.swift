import Foundation
import SwiftUI

/// Thuật toán thiên văn Paul Schlyter & Jean Meeus tính toán tọa độ biểu kiến
/// (Góc ngẩng Altitude & Phương vị Azimuth) thời gian thực của các hành tinh trong Hệ Mặt Trời
/// đối với vị trí quan sát trên Trái Đất (Topocentric Coordinates).
/// Tương thích 100% với SolarSystemEngine.kt trên Android
enum SolarSystemEngine {

    static func normalizeDeg(_ deg: Double) -> Double {
        var v = deg.truncatingRemainder(dividingBy: 360.0)
        if v < 0.0 { v += 360.0 }
        return v
    }

    static func solveKepler(mRad: Double, e: Double) -> Double {
        var E = mRad + e * sin(mRad) * (1.0 + e * cos(mRad))
        for _ in 0...6 {
            let dE = (E - e * sin(E) - mRad) / (1.0 - e * cos(E))
            E -= dE
            if abs(dE) < 1e-7 { break }
        }
        return E
    }

    static func getZodiacConstellation(eclipticLonDeg: Double) -> (String, String) {
        let norm = normalizeDeg(eclipticLonDeg)
        let idx = (Int(norm / 30.0)) % 12
        switch idx {
        case 0: return ("Bạch Dương", "♈")
        case 1: return ("Kim Ngưu", "♉")
        case 2: return ("Song Tử", "♊")
        case 3: return ("Cự Giải", "♋")
        case 4: return ("Sư Tử", "♌")
        case 5: return ("Xử Nữ", "♍")
        case 6: return ("Thiên Bình", "♎")
        case 7: return ("Bọ Cạp", "♏")
        case 8: return ("Nhân Mã", "♐")
        case 9: return ("Ma Kết", "♑")
        case 10: return ("Bảo Bình", "♒")
        case 11: return ("Song Ngư", "♓")
        default: return ("Bạch Dương", "♈")
        }
    }

    /// Tính toán vị trí tất cả các hành tinh cho thời điểm timeMillis tại tọa độ (latitude, longitude)
    static func calculateAllBodies(
        timeMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        latitude: Double = 21.0285, // Mặc định Hà Nội
        longitude: Double = 105.8542
    ) -> [PlanetInfo] {
        let jd = (Double(timeMillis) / 86400000.0) + 2440587.5
        let d = jd - 2451543.5 // Số ngày từ kỷ nguyên J2000.0

        let eclDeg = 23.4393 - 3.563e-7 * d
        let eclRad = eclDeg * .pi / 180.0

        // Tính vị trí Mặt Trời
        let wSun = normalizeDeg(282.9404 + 4.70935e-5 * d)
        let aSun = 1.000000
        let eSun = 0.016709 - 1.151e-9 * d
        let mSun = normalizeDeg(356.0470 + 0.9856002585 * d)
        let mSunRad = mSun * .pi / 180.0
        let vSunRad = mSunRad + (2.0 * eSun - pow(eSun, 3) / 4.0) * sin(mSunRad) + 1.25 * pow(eSun, 2) * sin(2.0 * mSunRad)
        let lonSunRad = wSun * .pi / 180.0 + vSunRad
        let rSun = aSun * (1.0 - eSun * eSun) / (1.0 + eSun * cos(vSunRad))
        let xs = rSun * cos(lonSunRad)
        let ys = rSun * sin(lonSunRad)
        let zs = 0.0

        // Giờ thiên văn Greenwich và địa phương (Local Sidereal Time)
        let gmstDeg = normalizeDeg(280.46061837 + 360.98564736629 * d)
        let lstDeg = normalizeDeg(gmstDeg + longitude)
        let lstRad = lstDeg * .pi / 180.0
        let latRad = latitude * .pi / 180.0

        var results = [PlanetInfo]()

        // 1. MẶT TRỜI
        do {
            let xeq = xs
            let yeq = ys * cos(eclRad) - zs * sin(eclRad)
            let zeq = ys * sin(eclRad) + zs * cos(eclRad)
            let raRad = atan2(yeq, xeq)
            let decRad = atan2(zeq, sqrt(xeq * xeq + yeq * yeq))
            let haRad = lstRad - raRad
            let (alt, az) = eqToHor(decRad: decRad, haRad: haRad, latRad: latRad)
            let (constName, constSym) = getZodiacConstellation(eclipticLonDeg: lonSunRad * 180.0 / .pi)

            results.append(
                PlanetInfo(
                    id: "SUN",
                    nameVi: "Mặt Trời",
                    nameEn: "Sun",
                    symbol: "☀️",
                    color: Color(red: 1.0, green: 0.835, blue: 0.31),
                    glowColor: Color(red: 1.0, green: 0.56, blue: 0.0),
                    altitude: alt,
                    azimuth: az,
                    distanceAu: rSun,
                    magnitude: -26.7,
                    constellationVi: constName,
                    constellationSymbol: constSym,
                    type: .sun,
                    descriptionVi: "Ngôi sao trung tâm của Hệ Mặt Trời, cung cấp nhiệt và ánh sáng nuôi dưỡng sự sống trên Trái Đất.",
                    observationTipVi: "Cảnh báo: Tuyệt đối KHÔNG nhìn trực tiếp bằng ống nhòm hoặc mắt thường qua kính thiên văn mà không có màng lọc mặt trời chuyên dụng.",
                    diameterKm: 1392700
                )
            )
        }

        // 2. MẶT TRĂNG
        do {
            let nMoon = normalizeDeg(125.1228 - 0.0529538083 * d)
            let iMoon = 5.1454
            let wMoon = normalizeDeg(318.0634 + 0.1643573223 * d)
            let aMoon = 60.2666 // Bán kính Trái Đất
            let eMoon = 0.054900
            let mMoon = normalizeDeg(115.3654 + 13.0649929509 * d)
            let mMoonRad = mMoon * .pi / 180.0

            let eRad = solveKepler(mRad: mMoonRad, e: eMoon)
            let xv = aMoon * (cos(eRad) - eMoon)
            let yv = aMoon * sqrt(1.0 - eMoon * eMoon) * sin(eRad)
            let rMoon = sqrt(xv * xv + yv * yv)
            let vMoon = atan2(yv, xv)

            let nRad = nMoon * .pi / 180.0
            let iRad = iMoon * .pi / 180.0
            let vwRad = vMoon + wMoon * .pi / 180.0

            let xh = rMoon * (cos(nRad) * cos(vwRad) - sin(nRad) * sin(vwRad) * cos(iRad))
            let yh = rMoon * (sin(nRad) * cos(vwRad) + cos(nRad) * sin(vwRad) * cos(iRad))
            let zh = rMoon * (sin(vwRad) * sin(iRad))

            let distAu = (rMoon * 6378.137) / 149597870.7

            let xeq = xh
            let yeq = yh * cos(eclRad) - zh * sin(eclRad)
            let zeq = yh * sin(eclRad) + zh * cos(eclRad)
            let raRad = atan2(yeq, xeq)
            let decRad = atan2(zeq, sqrt(xeq * xeq + yeq * yeq))
            let haRad = lstRad - raRad
            let (alt, az) = eqToHor(decRad: decRad, haRad: haRad, latRad: latRad)

            let moonLonDeg = normalizeDeg(atan2(yh, xh) * 180.0 / .pi)
            let sunLonDeg = normalizeDeg(lonSunRad * 180.0 / .pi)
            let elongationDeg = normalizeDeg(moonLonDeg - sunLonDeg)
            let phaseFrac = (1.0 - cos(elongationDeg * .pi / 180.0)) / 2.0
            let phasePct = max(0, min(100, Int((phaseFrac * 100.0).rounded())))

            let (constName, constSym) = getZodiacConstellation(eclipticLonDeg: moonLonDeg)

            let phaseTitle: String
            switch phasePct {
            case ..<5:
                phaseTitle = "Trăng Non (New Moon)"
            default:
                if elongationDeg < 90 {
                    phaseTitle = "Trăng Lưỡi Liềm Đầu Tháng (\(phasePct)%)"
                } else if elongationDeg < 170 {
                    phaseTitle = "Trăng Bán Nguyệt Đầu Tháng (\(phasePct)%)"
                } else if elongationDeg < 190 {
                    phaseTitle = "Trăng Tròn (Full Moon \(phasePct)%)"
                } else if elongationDeg < 270 {
                    phaseTitle = "Trăng Khuyết Cuối Tháng (\(phasePct)%)"
                } else {
                    phaseTitle = "Trăng Lưỡi Liềm Cuối Tháng (\(phasePct)%)"
                }
            }

            results.append(
                PlanetInfo(
                    id: "MOON",
                    nameVi: "Mặt Trăng",
                    nameEn: "Moon",
                    symbol: "🌙",
                    color: Color(red: 236/255.0, green: 239/255.0, blue: 241/255.0),
                    glowColor: Color(red: 144/255.0, green: 202/255.0, blue: 249/255.0),
                    altitude: alt,
                    azimuth: az,
                    distanceAu: distAu,
                    magnitude: -12.5 + Float(1.0 - phaseFrac) * 4.0,
                    constellationVi: constName,
                    constellationSymbol: constSym,
                    type: .moon,
                    descriptionVi: "Vệ tinh tự nhiên duy nhất của Trái Đất. Trạng thái pha hiện tại: \(phaseTitle).",
                    observationTipVi: "Thời điểm tốt nhất để quan sát các miệng hố va chạm và rặng núi là quanh đường phân chia sáng-tối (terminator).",
                    diameterKm: 3474,
                    phasePercent: phasePct
                )
            )
        }

        // 3. CÁC HÀNH TINH (Sao Thủy, Sao Kim, Sao Hỏa, Sao Mộc, Sao Thổ, Thiên Vương, Hải Vương)
        struct PlanetParams {
            let id: String
            let nameVi: String
            let nameEn: String
            let symbol: String
            let color: Color
            let glowColor: Color
            let N0: Double; let Nd: Double
            let i0: Double; let idRate: Double
            let w0: Double; let wd: Double
            let a0: Double; let ad: Double
            let e0: Double; let ed: Double
            let M0: Double; let Md: Double
            let baseMag: Float
            let diameterKm: Int64
            let descriptionVi: String
            let tipVi: String
        }

        let planetParamsList: [PlanetParams] = [
            PlanetParams(
                id: "MERCURY",
                nameVi: "Sao Thủy",
                nameEn: "Mercury",
                symbol: "☿",
                color: Color(red: 207/255.0, green: 216/255.0, blue: 220/255.0),
                glowColor: Color(red: 144/255.0, green: 164/255.0, blue: 174/255.0),
                N0: 48.3313, Nd: 3.24587e-5,
                i0: 7.0047, idRate: 5.00e-8,
                w0: 29.1241, wd: 1.01444e-5,
                a0: 0.387098, ad: 0.0,
                e0: 0.205635, ed: 5.59e-10,
                M0: 168.6562, Md: 4.0923344368,
                baseMag: -0.4,
                diameterKm: 4879,
                descriptionVi: "Hành tinh gần Mặt Trời nhất và nhỏ nhất trong Hệ Mặt Trời. Nhiệt độ dao động từ -180°C ban đêm đến 430°C ban ngày.",
                tipVi: "Quan sát tốt nhất vào lúc chạng vạng hoàng hôn hoặc bình minh khi đạt góc ly giác cực đại."
            ),
            PlanetParams(
                id: "VENUS",
                nameVi: "Sao Kim",
                nameEn: "Venus",
                symbol: "♀",
                color: Color(red: 255/255.0, green: 249/255.0, blue: 196/255.0),
                glowColor: Color(red: 255/255.0, green: 213/255.0, blue: 79/255.0),
                N0: 76.6799, Nd: 2.46590e-5,
                i0: 3.3946, idRate: 2.75e-8,
                w0: 54.8910, wd: 1.38374e-5,
                a0: 0.723330, ad: 0.0,
                e0: 0.006773, ed: -1.302e-9,
                M0: 48.0052, Md: 1.6021302244,
                baseMag: -4.4,
                diameterKm: 12104,
                descriptionVi: "Thiên thể tự nhiên sáng thứ ba trên bầu trời đêm sau Mặt Trời và Mặt Trăng. Dân gian gọi là Sao Hôm (hoàng hôn) hoặc Sao Mai (bình minh).",
                tipVi: "Dễ dàng nhìn thấy bằng mắt thường ngay cả khi hoàng hôn chưa tắt hẳn vì phản xạ ánh sáng cực mạnh từ lớp mây axit sulfuric dày đặc."
            ),
            PlanetParams(
                id: "MARS",
                nameVi: "Sao Hỏa",
                nameEn: "Mars",
                symbol: "♂",
                color: Color(red: 255/255.0, green: 112/255.0, blue: 67/255.0),
                glowColor: Color(red: 216/255.0, green: 67/255.0, blue: 21/255.0),
                N0: 49.5574, Nd: 2.11081e-5,
                i0: 1.8497, idRate: -1.78e-8,
                w0: 286.5016, wd: 2.92961e-5,
                a0: 1.523688, ad: 0.0,
                e0: 0.093405, ed: 2.516e-9,
                M0: 18.6021, Md: 0.5240207766,
                baseMag: -1.2,
                diameterKm: 6779,
                descriptionVi: "Hành tinh Đỏ thứ 4 từ Mặt Trời. Có núi lửa Olympus Mons cao nhất Hệ Mặt Trời (21.9 km) và hẻm núi Valles Marineris kỳ vĩ.",
                tipVi: "Hiện lên với ánh sáng đỏ cam đặc trưng rất dễ phân biệt bằng mắt thường trên nền sao."
            ),
            PlanetParams(
                id: "JUPITER",
                nameVi: "Sao Mộc",
                nameEn: "Jupiter",
                symbol: "♃",
                color: Color(red: 255/255.0, green: 204/255.0, blue: 128/255.0),
                glowColor: Color(red: 239/255.0, green: 108/255.0, blue: 0/255.0),
                N0: 100.4542, Nd: 2.76854e-5,
                i0: 1.3030, idRate: -1.557e-7,
                w0: 273.8777, wd: 1.64505e-5,
                a0: 5.20256, ad: 0.0,
                e0: 0.048498, ed: 4.469e-9,
                M0: 19.8950, Md: 0.0830853001,
                baseMag: -2.7,
                diameterKm: 139820,
                descriptionVi: "Hành tinh lớn nhất trong Hệ Mặt Trời, khối lượng lớn hơn 2.5 lần tất cả các hành tinh khác cộng lại. Nổi tiếng với Vết Đỏ Lớn khổng lồ.",
                tipVi: "Dùng ống nhòm thông thường có thể nhìn thấy 4 vệ tinh Galileo lớn: Io, Europa, Ganymede và Callisto xếp thẳng hàng."
            ),
            PlanetParams(
                id: "SATURN",
                nameVi: "Sao Thổ",
                nameEn: "Saturn",
                symbol: "♄",
                color: Color(red: 255/255.0, green: 224/255.0, blue: 130/255.0),
                glowColor: Color(red: 255/255.0, green: 179/255.0, blue: 0/255.0),
                N0: 113.6634, Nd: 2.38980e-5,
                i0: 2.4886, idRate: -1.081e-7,
                w0: 339.3939, wd: 2.97661e-5,
                a0: 9.55475, ad: 0.0,
                e0: 0.055546, ed: -9.499e-9,
                M0: 316.9670, Md: 0.0334442282,
                baseMag: 0.4,
                diameterKm: 116460,
                descriptionVi: "Chúa tể những chiếc vành đai. Hệ thống vành đai ngoạn mục cấu thành từ hàng tỷ hạt băng và bụi đá quay quanh hành tinh khí.",
                tipVi: "Kính thiên văn cỡ nhỏ (độ phóng đại 30x trở lên) là đủ để chiêm ngưỡng rõ ràng vành đai và vệ tinh khổng lồ Titan."
            ),
            PlanetParams(
                id: "URANUS",
                nameVi: "Sao Thiên Vương",
                nameEn: "Uranus",
                symbol: "♅",
                color: Color(red: 128/255.0, green: 222/255.0, blue: 234/255.0),
                glowColor: Color(red: 0/255.0, green: 172/255.0, blue: 193/255.0),
                N0: 74.0005, Nd: 1.3978e-5,
                i0: 0.7733, idRate: 1.9e-8,
                w0: 96.6612, wd: 3.0565e-5,
                a0: 19.18171, ad: -1.55e-8,
                e0: 0.047318, ed: 7.45e-9,
                M0: 142.5905, Md: 0.011725806,
                baseMag: 5.7,
                diameterKm: 50724,
                descriptionVi: "Hành tinh băng khổng lồ có bầu khí quyển chứa hydro, heli và methane tạo nên màu lục lam thơ mộng. Trục tự quay nghiêng tới 97.8°.",
                tipVi: "Nằm ở ngưỡng nhạy của mắt thường trong điều kiện trời đêm cực tối (Bortle 1-2). Nên dùng ống nhòm để xác định dưới dạng chấm xanh nhạt."
            ),
            PlanetParams(
                id: "NEPTUNE",
                nameVi: "Sao Hải Vương",
                nameEn: "Neptune",
                symbol: "♆",
                color: Color(red: 100/255.0, green: 181/255.0, blue: 246/255.0),
                glowColor: Color(red: 25/255.0, green: 118/255.0, blue: 210/255.0),
                N0: 131.7806, Nd: 3.0173e-5,
                i0: 1.7700, idRate: -2.55e-7,
                w0: 272.8461, wd: -6.027e-6,
                a0: 30.05826, ad: 3.313e-8,
                e0: 0.008606, ed: 2.15e-9,
                M0: 260.2471, Md: 0.005995147,
                baseMag: 7.8,
                diameterKm: 49244,
                descriptionVi: "Hành tinh xa xôi nhất trong Hệ Mặt Trời. Có những cơn bão dữ dội nhất với tốc độ gió đo được lên tới 2,100 km/h.",
                tipVi: "Cần kính thiên văn khẩu độ từ 70mm trở lên để phân biệt đĩa màu xanh lam thẫm giữa hàng ngàn ngôi sao nền."
            )
        ]

        for p in planetParamsList {
            let n = normalizeDeg(p.N0 + p.Nd * d)
            let i = p.i0 + p.idRate * d
            let w = normalizeDeg(p.w0 + p.wd * d)
            let a = p.a0 + p.ad * d
            let e = p.e0 + p.ed * d
            let m = normalizeDeg(p.M0 + p.Md * d)
            let mRad = m * .pi / 180.0

            let eRad = solveKepler(mRad: mRad, e: e)
            let xv = a * (cos(eRad) - e)
            let yv = a * sqrt(1.0 - e * e) * sin(eRad)
            let r = sqrt(xv * xv + yv * yv)
            let v = atan2(yv, xv)

            let nRad = n * .pi / 180.0
            let iRad = i * .pi / 180.0
            let vwRad = v + w * .pi / 180.0

            let xh = r * (cos(nRad) * cos(vwRad) - sin(nRad) * sin(vwRad) * cos(iRad))
            let yh = r * (sin(nRad) * cos(vwRad) + cos(nRad) * sin(vwRad) * cos(iRad))
            let zh = r * (sin(vwRad) * sin(iRad))

            // Tọa độ địa tâm (Geocentric)
            let xg = xh + xs
            let yg = yh + ys
            let zg = zh + zs
            let distAu = sqrt(xg * xg + yg * yg + zg * zg)

            // Đổi sang tọa độ xích đạo (Equatorial)
            let xeq = xg
            let yeq = yg * cos(eclRad) - zg * sin(eclRad)
            let zeq = yg * sin(eclRad) + zg * cos(eclRad)
            let raRad = atan2(yeq, xeq)
            let decRad = atan2(zeq, sqrt(xeq * xeq + yeq * yeq))

            let haRad = lstRad - raRad
            let (alt, az) = eqToHor(decRad: decRad, haRad: haRad, latRad: latRad)

            let eclLon = normalizeDeg(atan2(yg, xg) * 180.0 / .pi)
            let (constName, constSym) = getZodiacConstellation(eclipticLonDeg: eclLon)

            let mag = p.baseMag + max(-5.0, 5.0 * Float(log10(r * distAu)))

            results.append(
                PlanetInfo(
                    id: p.id,
                    nameVi: p.nameVi,
                    nameEn: p.nameEn,
                    symbol: p.symbol,
                    color: p.color,
                    glowColor: p.glowColor,
                    altitude: alt,
                    azimuth: az,
                    distanceAu: distAu,
                    magnitude: mag,
                    constellationVi: constName,
                    constellationSymbol: constSym,
                    type: .planet,
                    descriptionVi: p.descriptionVi,
                    observationTipVi: p.tipVi,
                    diameterKm: p.diameterKm
                )
            )
        }

        return results
    }

    /// Tính toán chuỗi điểm trên Đường Hoàng Đạo (Ecliptic line) để vẽ quỹ đạo mặt phẳng hệ mặt trời
    static func calculateEclipticPath(
        timeMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        latitude: Double = 21.0285,
        longitude: Double = 105.8542,
        stepDeg: Int = 10
    ) -> [(Float, Float)] {
        let jd = (Double(timeMillis) / 86400000.0) + 2440587.5
        let d = jd - 2451543.5
        let eclRad = (23.4393 - 3.563e-7 * d) * .pi / 180.0

        let gmstDeg = normalizeDeg(280.46061837 + 360.98564736629 * d)
        let lstRad = normalizeDeg(gmstDeg + longitude) * .pi / 180.0
        let latRad = latitude * .pi / 180.0

        var points = [(Float, Float)]()
        for lonDeg in stride(from: 0, to: 360, by: stepDeg) {
            let lonRad = Double(lonDeg) * .pi / 180.0
            let xg = cos(lonRad)
            let yg = sin(lonRad)
            let zg = 0.0

            let xeq = xg
            let yeq = yg * cos(eclRad) - zg * sin(eclRad)
            let zeq = yg * sin(eclRad) + zg * cos(eclRad)

            let raRad = atan2(yeq, xeq)
            let decRad = atan2(zeq, sqrt(xeq * xeq + yeq * yeq))
            let haRad = lstRad - raRad
            let (alt, az) = eqToHor(decRad: decRad, haRad: haRad, latRad: latRad)
            points.append((alt, az))
        }
        return points
    }

    private static func eqToHor(decRad: Double, haRad: Double, latRad: Double) -> (Float, Float) {
        let sinAlt = sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(haRad)
        let altRad = asin(max(-1.0, min(1.0, sinAlt)))
        let altDeg = Float(altRad * 180.0 / .pi)

        let cosAz = (sin(decRad) - sinAlt * sin(latRad)) / (cos(altRad) * cos(latRad))
        let sinAz = -cos(decRad) * sin(haRad) / cos(altRad)
        var azDeg = Float(atan2(sinAz, cosAz) * 180.0 / .pi)
        if azDeg < 0.0 { azDeg += 360.0 }

        return (altDeg, azDeg)
    }
}
