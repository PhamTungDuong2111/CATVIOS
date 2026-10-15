# CATV-IOS (Chụp Ảnh Thiên Văn & Máy Ảnh Tiêu Chuẩn cho iOS)

Ứng dụng máy ảnh và chụp ảnh thiên văn iOS Native hoàn chỉnh 100% bằng **Swift** và **SwiftUI**, được thiết kế và xây dựng tương đồng 1:1 cả về tính năng, thuật toán lẫn giao diện với phiên bản Android **ChupAnhTV-fixed** (CATV-ADR).

---

## 🌌 Các tính năng nổi bật (Tương đồng 100% bản Android ChupAnhTV-fixed)

### 1. 4 Chế độ chụp & quay linh hoạt
- **ẢNH (Photo)**: Chụp ảnh độ phân giải cao tiêu chuẩn với tự động lấy nét (Continuous Auto-Focus) và đo sáng (Auto-Exposure).
- **VIDEO (FHD)**: Quay video HD/FHD kèm âm thanh chất lượng cao và bộ đếm thời gian thực `MM:SS` có chấm đỏ nhấp nháy.
- **THIÊN VĂN (Astro)**: Chế độ chụp phơi sáng thiên văn chuyên sâu:
  - **Ngân Hà (Deep Sky)**: Xếp chồng trung bình lũy tiến (Running Average) giúp khử nhiễu hạt ISO cao và làm rõ các chi tiết tinh vân mờ.
  - **Khử Vệ Tinh (Kappa-Sigma Outlier Rejection)**: Tự động phát hiện và loại bỏ các vệt sáng bất thường do vệ tinh nhân tạo hoặc máy bay bay ngang khung hình.
  - **Vệt Sao (Star Trails)**: Phơi sáng xếp chồng điểm sáng cực đại (Max Intensity Stacking) để ghi lại chuyển động quay của các vì sao quanh thiên cực.
- **CHUYÊN NGHIỆP (Pro)**: Tùy chỉnh thủ công toàn bộ các thông số: ISO (400 - 12800), Tốc độ màn trập (0.5s - 30s), và khóa nét vô cực (`∞ Vô cực`).

### 2. Thuật toán Cân chỉnh Sao & Xử lý ảnh Thiên văn
- **Nhận diện sao Sub-pixel Centroid (`StarDetector`)**: Sử dụng thư viện tăng tốc phần cứng Apple `Accelerate` (`vDSP`) để quét cực đại địa phương và tính trọng tâm sao đạt độ chính xác dưới pixel.
- **Kéo dãn độ tương phản MTF Stretch**: Bộ thuật toán Midtone Transfer Function kết hợp Black Point clipping giúp kéo sáng bụi khí tinh vân và dải Ngân Hà mà không làm cháy sáng các vì sao.
- **Biểu đồ sắc độ Histogram Logarithmic (`HistogramView`)**: Phân tích phổ sáng thời gian thực theo hàm logarit chuẩn thiên văn.

### 3. Thử nghiệm Bầu trời Ảo (`SkySimulator`)
- Tích hợp động cơ mô phỏng bầu trời đêm với 80 ngôi sao xoay theo góc quay Trái Đất, dải sáng tinh vân Ngân Hà (Milky Way gradient) và nhiễu hạt cảm biến ISO cao.
- Cho phép người dùng và lập trình viên kiểm thử tính năng chụp và xếp chồng sao mọi lúc mọi nơi ngay cả khi ở trong nhà, ban ngày, hoặc trên máy ảo **iOS Simulator** không có camera thật.

### 4. Thước thủy Chân trời & La bàn (`LevelerOverlay`)
- Sử dụng cảm biến gia tốc và con quay hồi chuyển `CoreMotion` để hiển thị thước thủy chân trời điện tử (Artificial Horizon Bar), tâm ngắm chữ thập, lưới 1/3 (Rule-of-Thirds Grid).
- Báo trạng thái cân bằng `✓ CHUẨN` khi góc nghiêng lệch dưới ±1.5°, kèm góc ngẩng (Pitch) và phương vị la bàn 8 hướng (`N`, `NE`, `E`, `SE`, `S`, `SW`, `W`, `NW`).

### 5. Chế độ quan sát ban đêm (Red Night Mode)
- Chuyển đổi toàn bộ giao diện sang tông màu đỏ bảo vệ thị giác thích nghi bóng tối của mắt (Dark-adapted vision) khi quan sát thiên văn đêm.

### 6. Quản lý và Lưu trữ kết quả (`ResultPreviewDialog`)
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
│   │   └── Info.plist                      # Cấp quyền Camera, Micro, Thư viện ảnh
│   ├── Camera/
│   │   ├── CameraManager.swift             # Quản lý AVCaptureSession, Photo, Video, Torch, ISO, Shutter
│   │   └── CameraModels.swift              # AppCameraMode, FlashMode, StackingMode, OrientationData, CameraState
│   ├── Stacking/
│   │   ├── AstroStackingEngine.swift       # Xếp chồng Deep Sky, Star Trails, Kappa-Sigma, MTF Stretch
│   │   ├── StarDetector.swift              # Nhận diện sao bằng Accelerate vDSP & Subpixel Centroid
│   │   └── SkySimulator.swift              # Mô phỏng bầu trời đêm với 80 sao & dải Ngân Hà
│   ├── Sensors/
│   │   └── MotionSensorManager.swift       # Thước thủy & góc nghiêng qua CoreMotion
│   ├── UI/
│   │   ├── MainCameraView.swift            # Màn hình chính điều phối giao diện
│   │   ├── CameraPreviewView.swift         # Khung ngắm AVCaptureVideoPreviewLayer & SkySimulator
│   │   ├── TopGlassBar.swift               # Thanh công cụ HUD trên (Flash, Leveler, Red, Histogram, Star badge)
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
* **Cảm biến con quay hồi chuyển**: `CoreMotion` (`CMMotionManager`).
* **Lưu trữ**: `Photos` (`PHPhotoLibrary`).
