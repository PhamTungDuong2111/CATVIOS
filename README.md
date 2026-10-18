# CATV-IOS (Chụp Ảnh Thiên Văn & Máy Ảnh Tiêu Chuẩn cho iOS)

Ứng dụng máy ảnh và chụp ảnh thiên văn iOS Native hoàn chỉnh 100% bằng **Swift** và **SwiftUI**, được thiết kế và xây dựng tương đồng 1:1 cả về tính năng, thuật toán lẫn giao diện với phiên bản Android **ChupAnhTV-fixed** (CATV-ADR).

---

## 🌌 Các tính năng nổi bật (Tương đồng 100% bản Android ChupAnhTV-fixed)

### 1. 4 Chế độ chụp & quay linh hoạt
- **ẢNH (Photo)**: Chụp ảnh độ phân giải cao tiêu chuẩn với tự động lấy nét (Continuous Auto-Focus) và đo sáng (Auto-Exposure).
- **VIDEO (FHD)**: Quay video HD/FHD kèm âm thanh chất lượng cao và bộ đếm thời gian thực `MM:SS` có chấm đỏ nhấp nháy.
- **THIÊN VĂN (Astro)**: Chế độ chụp phơi sáng thiên văn chuyên sâu (mặc định khởi chạy):
  - **Ngân Hà (Deep Sky)**: Xếp chồng trung bình lũy tiến (Running Average) giúp khử nhiễu hạt ISO cao và làm rõ các chi tiết tinh vân mờ.
  - **Khử Vệ Tinh (Kappa-Sigma Outlier Rejection)**: Tự động phát hiện và loại bỏ các vệt sáng bất thường do vệ tinh nhân tạo hoặc máy bay bay ngang khung hình.
  - **Vệt Sao (Star Trails)**: Phơi sáng xếp chồng điểm sáng cực đại (Max Intensity Stacking) để ghi lại chuyển động quay của các vì sao quanh thiên cực.
- **CHUYÊN NGHIỆP (Pro)**: Tùy chỉnh thủ công toàn bộ các thông số: ISO (400 - 12800), Tốc độ màn trập (0.5s - 30s), và khóa nét vô cực (`∞ Vô cực`).

### 2. Định vị & Hiển thị Vị trí Các Hành Tinh (AR Solar System Planetary Overlay)
- **Thuật toán cơ học thiên thể Paul Schlyter & Jean Meeus (`SolarSystemEngine`)**:
  - Tính toán chính xác vị trí góc ngẩng (Altitude) và phương vị la bàn (Azimuth) thời gian thực của Mặt Trời, Mặt Trăng (kèm tính tuần trăng/pha sáng và tỷ lệ chiếu sáng), Sao Kim, Sao Mộc, Sao Hỏa, Sao Thổ, Sao Thủy, Sao Thiên Vương, Sao Hải Vương.
  - Tích hợp định vị GPS/CoreLocation tự động và quy đổi tọa độ địa tâm (Topocentric coordinates).
- **Thực tế ảo tăng cường AR Viewfinder (`PlanetOverlay`)**:
  - Chiếu 3D (Perspective Pinhole Projection) vị trí các hành tinh lên màn hình camera theo ma trận xoay cảm biến góc nghiêng và la bàn `CoreMotion`.
  - Vẽ đĩa hành tinh chi tiết: Vành đai Sao Thổ (Saturn rings), dải mây Sao Mộc (Jupiter cloud bands), bề mặt đỏ Sao Hỏa, đĩa sáng lấp lánh Sao Kim, tuần trăng thực của Mặt Trăng, quầng nhật hoa Mặt Trời.
  - Đường Hoàng Đạo (Ecliptic): Hiển thị mặt phẳng quỹ đạo hành tinh uốn cong dạng nét đứt trên vòm trời.
- **Mũi tên chỉ hướng ngoài màn hình (Off-screen Directional Indicators)**:
  - Khi điện thoại để trên bàn hoặc quay về hướng khác, các thẻ chỉ báo viền màn hình (`[ 🪐 Sao Mộc ➤ ]`) chỉ chính xác hướng và góc lệch để người dùng lia máy tìm thấy hành tinh ngay lập tức.
- **Thanh tra cứu hành tinh nhanh (`PlanetQuickBar`) & Dẫn đường mục tiêu (Target Guidance Lock)**:
  - Thanh cuộn ngang hiển thị danh sách hành tinh sắp xếp theo độ cao trên bầu trời.
  - Chạm vào hành tinh để kích hoạt vòng ngắm radar dẫn đường, hướng dẫn người dùng xoay và ngẩng máy đến khi khóa mục tiêu (`🎯 ĐÃ KHÓA MỤC TIÊU`).
  - Hộp thoại chi tiết thiên văn học (`PlanetDetailDialog`): Khoảng cách (AU/triệu km), cấp sao biểu kiến (Magnitude), chòm sao hoàng đạo, đường kính và mẹo quan sát.

### 3. Thuật toán Cân chỉnh Sao & Xử lý ảnh Thiên văn
- **Nhận diện sao Sub-pixel Centroid (`StarDetector`)**: Sử dụng thư viện tăng tốc phần cứng Apple `Accelerate` (`vDSP`) để quét cực đại địa phương và tính trọng tâm sao đạt độ chính xác dưới pixel.
- **Khử ô nhiễm ánh sáng nền trời (`BackgroundExtraction`)**: Ước tính gradient ô nhiễm ánh sáng 4 góc và trừ bỏ gradient giúp nền trời phẳng mịn, đen tuyền.
- **Kéo dãn độ tương phản MTF Stretch**: Bộ thuật toán Midtone Transfer Function kết hợp Black Point clipping giúp kéo sáng bụi khí tinh vân và dải Ngân Hà mà không làm cháy sáng các vì sao.
- **Biểu đồ sắc độ Histogram Logarithmic (`HistogramView`)**: Phân tích phổ sáng thời gian thực theo hàm logarit chuẩn thiên văn.

### 4. Thử nghiệm Bầu trời Ảo (`SkySimulator`)
- Tích hợp động cơ mô phỏng bầu trời đêm với 80 ngôi sao xoay theo góc quay Trái Đất, dải sáng tinh vân Ngân Hà (Milky Way gradient) và nhiễu hạt cảm biến ISO cao.
- Cho phép người dùng và lập trình viên kiểm thử tính năng chụp và xếp chồng sao mọi lúc mọi nơi ngay cả khi ở trong nhà, ban ngày, hoặc trên máy ảo **iOS Simulator** không có camera thật.

### 5. Thước thủy Chân trời & La bàn (`HorizonLevelerOverlay`)
- Sử dụng cảm biến gia tốc và con quay hồi chuyển `CoreMotion` để hiển thị thước thủy chân trời điện tử (Artificial Horizon Bar), tâm ngắm chữ thập, lưới 1/3 (Rule-of-Thirds Grid).
- Báo trạng thái cân bằng `✓ CHUẨN` khi góc nghiêng lệch dưới ±1.5°, kèm góc ngẩng (Pitch) và phương vị la bàn 8 hướng (`N`, `NE`, `E`, `SE`, `S`, `SW`, `W`, `NW`).

### 6. Chế độ quan sát ban đêm (Red Night Mode)
- Chuyển đổi toàn bộ giao diện sang tông màu đỏ bảo vệ thị giác thích nghi bóng tối của mắt (Dark-adapted vision) khi quan sát thiên văn đêm.

### 7. Quản lý và Lưu trữ kết quả (`CapturedMediaDetailSheet`)
- Xem ảnh phóng to sau khi chụp/xếp chồng.
- Thống kê chi tiết: số khung ảnh đã chồng, số khung bị loại bỏ, tổng thời gian phơi sáng tích lũy.
- Tự động lưu hoặc bấm nút lưu trực tiếp vào ứng dụng **Photos** (Camera Roll) của iOS.

---

## 🚀 Hướng dẫn mở và chạy trên macOS (Xcode)

### 1. Yêu cầu hệ thống
* **Máy tính**: macOS Monterey / Ventura / Sonoma / Sequoia.
* **Công cụ**: Xcode 15.0 trở lên.
* **Hệ điều hành thiết bị mục tiêu**: iOS 16.0 trở lên (hỗ trợ cả iPhone và iPad).

### 2. Các bước mở dự án & build vào máy thật
1. Tải hoặc clone mã nguồn về máy Mac:
   ```bash
   git clone https://github.com/PhamTungDuong2111/CATVIOS.git
   ```
2. Mở tệp `CATV-IOS.xcodeproj` bằng **Xcode**.
3. Trong cột bên trái (Project Navigator), chọn root project **CATV-IOS**:
   - Chọn target **CATV-IOS** -> tab **Signing & Capabilities**.
   - Tại mục **Team**, chọn tài khoản Apple ID của bạn (Personal Team). Xcode sẽ tự động cấp chứng chỉ miễn phí (Provisioning Profile).
4. Cắm iPhone thật vào máy Mac bằng cáp:
   - Trên thanh công cụ phía trên Xcode, chọn thiết bị iPhone của bạn làm mục tiêu chạy (Target Device).
   - Nhấn nút **Run (Cmd + R)** để biên dịch và nạp app vào máy thật.
5. *Lưu ý lần đầu nạp vào máy thật*: Trên iPhone vào **Cài đặt -> Cài đặt chung -> Quản lý VPN & Thiết bị** -> Chọn Apple ID của bạn và bấm **Tin cậy (Trust)** để khởi chạy app.

---

## 📁 Cấu trúc thư mục mã nguồn

```
CATV-IOS/
├── CATV-IOS.xcodeproj/
│   └── project.pbxproj                     # Cấu hình dự án Xcode
├── CATV-IOS/
│   ├── App/
│   │   ├── CATVIOSApp.swift                # Điểm khởi chạy @main SwiftUI
│   │   └── Info.plist                      # Cấp quyền Camera, Micro, Thư viện ảnh, Vị trí GPS
│   ├── Astro/
│   │   ├── PlanetInfo.swift                # Mô hình dữ liệu thiên thể, góc ngẩng, phương vị, pha trăng
│   │   ├── SolarSystemEngine.swift         # Thuật toán thiên văn Paul Schlyter & Jean Meeus
│   │   └── AstroLocationManager.swift      # Quản lý vị trí GPS qua CoreLocation
│   ├── Camera/
│   │   ├── CameraManager.swift             # Quản lý AVCaptureSession, Photo, Video, Torch, ISO, Shutter
│   │   └── CameraModels.swift              # AppCameraMode, FlashMode, StackingMode, OrientationData (3x3 Matrix)
│   ├── Stacking/
│   │   ├── AstroStackingEngine.swift       # Xếp chồng Deep Sky, Star Trails, Kappa-Sigma, MTF Stretch
│   │   ├── StarDetector.swift              # Nhận diện sao bằng Accelerate vDSP & Subpixel Centroid
│   │   ├── SkySimulator.swift              # Mô phỏng bầu trời đêm với 80 sao & dải Ngân Hà
│   │   └── BackgroundExtraction.swift      # Khử ô nhiễm ánh sáng và làm phẳng nền trời
│   ├── Sensors/
│   │   └── MotionSensorManager.swift       # Thước thủy & ma trận xoay 3D qua CoreMotion
│   ├── UI/
│   │   ├── MainCameraView.swift            # Màn hình chính điều phối giao diện
│   │   ├── CameraPreviewView.swift         # Khung ngắm AVCaptureVideoPreviewLayer & SkySimulator
│   │   ├── TopGlassBar.swift               # Thanh công cụ HUD trên (Flash, Leveler, Planet AR, Red, Histogram)
│   │   ├── PlanetOverlay.swift             # Chiếu 3D AR vòm trời, đĩa hành tinh, đường hoàng đạo & radar
│   │   ├── PlanetQuickBar.swift            # Thanh tra cứu nhanh hành tinh cuộn ngang
│   │   ├── PlanetDetailDialog.swift        # Hộp thoại chi tiết khoa học, tọa độ & khóa mục tiêu
│   │   ├── ModeCarousel.swift              # Băng chuyền chọn chế độ (Ảnh, Video, Thiên văn, Pro)
│   │   ├── AstroControlPanel.swift         # Bảng trượt chỉnh ISO, Shutter, Frame, Stretch
│   │   ├── BottomControlBar.swift          # Nút chụp thông minh, thumbnail, lật camera
│   │   ├── HorizonLevelerOverlay.swift     # Thước thủy chân trời, la bàn, lưới 1/3
│   │   ├── HistogramView.swift             # Biểu đồ sắc độ Histogram Logarithmic
│   │   └── CapturedMediaDetailSheet.swift  # Hộp thoại xem lại kết quả xếp chồng và lưu Photos
│   └── Utilities/
│       └── PhotoLibraryExporter.swift      # Xuất ảnh/video vào Photos Album
└── README.md
```

---

## 🛠 Công nghệ & Thư viện sử dụng
* **Ngôn ngữ**: Swift 5.0+ (Thuần Native 100%, không phụ thuộc thư viện ngoài).
* **Giao diện**: SwiftUI kết hợp UIKit (`UIViewRepresentable`).
* **Camera & Video**: `AVFoundation` (`AVCaptureSession`, `AVCapturePhotoOutput`, `AVCaptureMovieFileOutput`, `AVCaptureVideoDataOutput`).
* **Xử lý ảnh & Tính toán nhanh**: `CoreImage`, `Accelerate` (`vDSP`), `CoreGraphics`.
* **Cảm biến & Định vị**: `CoreMotion` (`CMMotionManager`), `CoreLocation` (`CLLocationManager`).
* **Lưu trữ**: `Photos` (`PHPhotoLibrary`).
