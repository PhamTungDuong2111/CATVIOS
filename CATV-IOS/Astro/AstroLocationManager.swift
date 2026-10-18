import Foundation
import CoreLocation
import Combine

/// Cấu trúc lưu vị trí quan sát thiên văn
struct AstroLocation: Equatable {
    var latitude: Double = 21.0285   // Mặc định Hà Nội, Việt Nam
    var longitude: Double = 105.8542
    var locationName: String = "Hà Nội, Việt Nam"
    var isGpsActive: Bool = false
}

/// Quản lý vị trí địa lý của thiết bị qua CoreLocation để phục vụ tính toán tọa độ hành tinh
/// Tương thích 100% với AstroLocationManager.kt trên Android
final class AstroLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()

    @Published var currentLocation = AstroLocation()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50.0 // Cập nhật khi di chuyển trên 50m
        start()
    }

    func start() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if let last = locationManager.location {
                updateFromLocation(last)
            }
            locationManager.startUpdatingLocation()
        default:
            // Sử dụng tọa độ mặc định Hà Nội
            break
        }
    }

    func stop() {
        locationManager.stopUpdatingLocation()
    }

    private func updateFromLocation(_ loc: CLLocation) {
        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        let name = String(format: "%.2f°N, %.2f°E", lat, lon)

        DispatchQueue.main.async {
            self.currentLocation = AstroLocation(
                latitude: lat,
                longitude: lon,
                locationName: name,
                isGpsActive: true
            )
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if let last = manager.location {
                updateFromLocation(last)
            }
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let best = locations.last else { return }
        updateFromLocation(best)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Tiếp tục dùng tọa độ mặc định
    }
}
