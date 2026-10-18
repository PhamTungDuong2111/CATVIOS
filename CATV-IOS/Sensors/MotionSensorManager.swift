import Foundation
import CoreMotion
import Combine

/// Quản lý cảm biến góc nghiêng và phương vị la bàn phục vụ Thước thủy (Leveler) và Định vị Hành tinh AR (Planet Overlay)
/// Tương thích 100% với AstroOrientationSensor.kt trên Android
final class MotionSensorManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?

    @Published var orientation = OrientationData()

    var isLevel: Bool { orientation.isLevel }
    var rollDegrees: Double { Double(orientation.roll) }
    var pitchDegrees: Double { Double(orientation.pitch) }
    var yawDegrees: Double { Double(orientation.azimuth) }

    init() {
        startMotionUpdates()
    }

    deinit {
        stopMotionUpdates()
    }

    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            // Giá trị mặc định khi chạy trên iOS Simulator
            let defPitch: Float = 45.0
            let defRoll: Float = 0.0
            let defAz: Float = 45.0
            let matrix = computeRotationMatrix(pitchDeg: defPitch, rollDeg: defRoll, azimuthDeg: defAz)
            self.orientation = OrientationData(
                pitch: defPitch,
                roll: defRoll,
                azimuth: defAz,
                isLevel: true,
                rotationMatrix: matrix
            )
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30Hz

        let availableFrames = CMMotionManager.availableAttitudeReferenceFrames()
        let refFrame: CMAttitudeReferenceFrame
        if availableFrames.contains(.xTrueNorthZVertical) {
            refFrame = .xTrueNorthZVertical
        } else if availableFrames.contains(.xMagneticNorthZVertical) {
            refFrame = .xMagneticNorthZVertical
        } else {
            refFrame = .xArbitraryCorrectedZVertical
        }

        motionManager.startDeviceMotionUpdates(using: refFrame)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self, let motion = self.motionManager.deviceMotion else { return }

            let attitude = motion.attitude
            let rollDeg = Float(attitude.roll * 180.0 / .pi)
            let pitchDeg = Float(attitude.pitch * 180.0 / .pi)
            var azimuthDeg = Float(attitude.yaw * 180.0 / .pi)
            if azimuthDeg < 0.0 {
                azimuthDeg += 360.0
            }

            let isLevel = abs(rollDeg) < 1.5 || abs(abs(rollDeg) - 180.0) < 1.5

            // Tính toán ma trận xoay 3D (3x3)
            let m = attitude.rotationMatrix
            var rotMat: [Float] = [
                Float(m.m11), Float(m.m12), Float(m.m13),
                Float(m.m21), Float(m.m22), Float(m.m23),
                Float(m.m31), Float(m.m32), Float(m.m33)
            ]

            // Nếu dữ liệu ma trận gần 0 do đang khởi tạo hoặc reference frame chưa có la bàn,
            // dùng ma trận giải tích từ pitch, roll, azimuth
            if abs(rotMat[0]) < 1e-4 && abs(rotMat[4]) < 1e-4 {
                rotMat = self.computeRotationMatrix(pitchDeg: pitchDeg, rollDeg: rollDeg, azimuthDeg: azimuthDeg)
            }

            DispatchQueue.main.async {
                self.orientation = OrientationData(
                    pitch: pitchDeg,
                    roll: rollDeg,
                    azimuth: azimuthDeg,
                    isLevel: isLevel,
                    rotationMatrix: rotMat
                )
            }
        }
    }

    func stopMotionUpdates() {
        timer?.invalidate()
        timer = nil
        motionManager.stopDeviceMotionUpdates()
    }

    /// Tính ma trận xoay 3x3 tương thích với hệ tọa độ thiên văn (X=East, Y=North, Z=Up)
    private func computeRotationMatrix(pitchDeg: Float, rollDeg: Float, azimuthDeg: Float) -> [Float] {
        let p = Double(pitchDeg) * .pi / 180.0
        let r = Double(rollDeg) * .pi / 180.0
        let az = Double(azimuthDeg) * .pi / 180.0

        // Forward vector (camera pointing out)
        // az: 0=North, 90=East
        let fx = sin(az) * cos(p)
        let fy = cos(az) * cos(p)
        let fz = sin(p)

        // Device Z points towards user (-Forward)
        let zx = -fx
        let zy = -fy
        let zz = -fz

        // Right vector when roll=0
        let rx0 = cos(az)
        let ry0 = -sin(az)
        let rz0 = 0.0

        // Up vector when roll=0
        let ux0 = -sin(az) * sin(p)
        let uy0 = -cos(az) * sin(p)
        let uz0 = cos(p)

        // Apply roll rotation around forward axis
        let cosR = cos(r)
        let sinR = sin(r)

        let xx = rx0 * cosR - ux0 * sinR
        let xy = ry0 * cosR - uy0 * sinR
        let xz = rz0 * cosR - uz0 * sinR

        let yx = rx0 * sinR + ux0 * cosR
        let yy = ry0 * sinR + uy0 * cosR
        let yz = rz0 * sinR + uz0 * cosR

        return [
            Float(xx), Float(xy), Float(xz),
            Float(yx), Float(yy), Float(yz),
            Float(zx), Float(zy), Float(zz)
        ]
    }
}
