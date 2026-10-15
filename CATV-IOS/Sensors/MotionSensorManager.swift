import Foundation
import CoreMotion
import Combine

/// Quản lý cảm biến góc nghiêng và phương vị la bàn phục vụ Thước thủy (Artificial Horizon Leveler)
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
            // Thiết lập giá trị mặc định khi chạy trên iOS Simulator
            self.orientation = OrientationData(pitch: 45.0, roll: 0.0, azimuth: 45.0, isLevel: true)
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30Hz
        motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self, let motion = self.motionManager.deviceMotion else { return }

            let attitude = motion.attitude
            let rollDeg = Float(attitude.roll * 180.0 / .pi)
            let pitchDeg = Float(attitude.pitch * 180.0 / .pi)
            var azimuthDeg = Float(attitude.yaw * 180.0 / .pi)
            if azimuthDeg < 0 {
                azimuthDeg += 360.0
            }

            let isLevel = abs(rollDeg) < 1.5 || abs(abs(rollDeg) - 180.0) < 1.5

            DispatchQueue.main.async {
                self.orientation = OrientationData(
                    pitch: pitchDeg,
                    roll: rollDeg,
                    azimuth: azimuthDeg,
                    isLevel: isLevel
                )
            }
        }
    }

    func stopMotionUpdates() {
        timer?.invalidate()
        timer = nil
        motionManager.stopDeviceMotionUpdates()
    }
}
