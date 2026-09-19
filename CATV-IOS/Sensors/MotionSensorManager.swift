import Foundation
import CoreMotion
import Combine

/// Quản lý cảm biến góc nghiêng và phương vị la bàn phục vụ Thước thủy (Artificial Horizon Leveler)
final class MotionSensorManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?

    @Published var rollDegrees: Double = 0.0
    @Published var pitchDegrees: Double = 0.0
    @Published var yawDegrees: Double = 0.0
    @Published var isLevel: Bool = false

    init() {
        startMotionUpdates()
    }

    deinit {
        stopMotionUpdates()
    }

    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30Hz

        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self, let motion = self.motionManager.deviceMotion else { return }

            // Chuyển đổi radian sang độ
            let attitude = motion.attitude
            let roll = attitude.roll * 180.0 / .pi
            let pitch = attitude.pitch * 180.0 / .pi
            let yaw = attitude.yaw * 180.0 / .pi

            DispatchQueue.main.async {
                self.rollDegrees = roll
                self.pitchDegrees = pitch
                self.yawDegrees = yaw
                // Cân bằng khi góc xoay lệch dưới 0.5 độ
                self.isLevel = abs(roll) < 0.5
            }
        }
    }

    func stopMotionUpdates() {
        timer?.invalidate()
        timer = nil
        motionManager.stopDeviceMotionUpdates()
    }
}
