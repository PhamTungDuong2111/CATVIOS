# CATV-IOS (Chụp Ảnh Thiên Văn & Máy Ảnh Tiêu Chuẩn cho iOS)

Ứng dụng máy ảnh iOS Native hoàn chỉnh 100% bằng **Swift** và **SwiftUI** (hoàn toàn không dùng Flutter), tích hợp đầy đủ tính năng tương ứng với phiên bản Android:
- **Chụp ảnh tiêu chuẩn (Photo)** với Auto-Focus liên tục và Auto-Exposure.
- **Quay video HD (Video)** kèm âm thanh và bộ đếm thời gian thực.
- **Chụp phơi sáng thiên văn (Astro)**: Xếp chồng sao Deep Sky (Running Average) và Star Trails (Vệt sao), kéo dãn MTF Stretch.
- **Chế độ Chuyên nghiệp (Pro)**: Chỉnh tay ISO và Tốc độ màn trập (Shutter Speed).
- **Thước thủy chân trời nhân tạo (Artificial Horizon Leveler) & La bàn**: Sử dụng CoreMotion.
- **Chế độ quan sát ban đêm (Red Night Mode)**: Lọc ánh sáng đỏ bảo vệ mắt.
- **Xem nhanh và chia sẻ**: Lưu trực tiếp vào ứng dụng Photos (Camera Roll) của iOS.

---

## 🚀 Hướng dẫn mở và chạy trên macOS (Xcode)

### 1. Yêu cầu hệ thống
* **Máy tính**: macOS Monterey / Ventura / Sonoma / Sequoia.
* **Công cụ**: Xcode 15.0 trở lên.
* **Hệ điều hành thiết bị mục tiêu**: iOS 16.0 trở lên (hỗ trợ cả iPhone và iPad).

### 2. Các bước khởi chạy
1. Sao chép hoặc di chuyển thư mục `CATV-IOS` sang máy Mac của bạn.
2. Nhấp đúp chuột vào tệp `CATV-IOS.xcodeproj` để mở dự án trong Xcode.
3. Trong thanh bên trái (Project Navigator), chọn target **CATV-IOS**:
   - Chuyển sang tab **Signing & Capabilities**.
   - Tại mục **Team**, chọn Apple ID cá nhân của bạn (Personal Team) để Xcode tự động tạo chứng chỉ chạy thử nghiệm.
4. Chọn thiết bị chạy ở thanh công cụ phía trên:
   - **Thiết bị thật (iPhone/iPad)**: Được khuyến nghị để trải nghiệm đầy đủ cảm biến camera thật, đèn flash, con quay hồi chuyển và micro.
   - **Máy ảo (iOS Simulator)**: Hỗ trợ kiểm tra toàn bộ giao diện, hiệu ứng nút bấm, chế độ màu và hoạt họa.
5. Nhấn tổ hợp phím `Cmd + R` hoặc bấm nút **Play (Run)** để bắt đầu biên dịch và chạy ứng dụng.

---

## 📁 Cấu trúc thư mục mã nguồn

```
CATV-IOS/
├── CATV-IOS.xcodeproj/
│   └── project.pbxproj                     # Tệp cấu hình Project Xcode
├── CATV-IOS/
│   ├── App/
│   │   ├── CATVIOSApp.swift                # Điểm khởi chạy @main SwiftUI
│   │   └── Info.plist                      # Quyền Camera, Microphone, Photo Library
│   ├── Camera/
│   │   ├── CameraManager.swift             # Quản lý AVCaptureSession, Photo/Video, Flash/Torch
│   │   └── CameraModels.swift              # AppCameraMode, FlashMode, CameraState
│   ├── Stacking/
│   │   ├── AstroStackingEngine.swift       # Xếp chồng Deep Sky, Star Trails, MTF Stretch
│   │   └── StarDetector.swift              # Nhận diện sao bằng Accelerate vDSP
│   ├── Sensors/
│   │   └── MotionSensorManager.swift       # Thước thủy & góc nghiêng qua CoreMotion
│   ├── UI/
│   │   ├── MainCameraView.swift            # Màn hình chính
│   │   ├── CameraPreviewView.swift         # Khung ngắm AVCaptureVideoPreviewLayer
│   │   ├── TopGlassBar.swift               # Thanh công cụ trên (Flash, Leveler, Red, Info)
│   │   ├── ModeCarousel.swift              # Băng chuyền chọn chế độ (Ảnh, Video, Thiên văn, Pro)
│   │   ├── AstroControlPanel.swift         # Bảng trượt chỉnh ISO, Exposure, MTF stretch
│   │   ├── BottomControlBar.swift          # Nút chụp thông minh, thumbnail, lật camera
│   │   ├── HorizonLevelerOverlay.swift     # Thước thủy chân trời & la bàn
│   │   ├── HistogramView.swift             # Biểu đồ sắc độ Histogram
│   │   └── CapturedMediaDetailSheet.swift  # Hộp thoại xem lại kết quả và chia sẻ
│   └── Utilities/
│       └── PhotoLibraryExporter.swift      # Xuất ảnh/video vào Photos Album
└── README.md
```

---

## 🛠 Công nghệ & Thư viện sử dụng
* **Ngôn ngữ**: Swift 5.0+ (Thuần Native 100%).
* **Giao diện**: SwiftUI kết hợp UIKit (`UIViewRepresentable`).
* **Camera & Video**: `AVFoundation` (`AVCaptureSession`, `AVCapturePhotoOutput`, `AVCaptureMovieFileOutput`).
* **Xử lý ảnh & Tính toán nhanh**: `CoreImage`, `Accelerate` (`vDSP`), `CoreGraphics`.
* **Cảm biến**: `CoreMotion` (`CMMotionManager`).
* **Lưu trữ**: `Photos` (`PHPhotoLibrary`).
