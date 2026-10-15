import SwiftUI

/// Hộp thoại xem kết quả chụp và xếp chồng thiên văn (Result Preview Dialog)
/// Tương thích 100% với ResultPreviewDialog.kt trên Android
struct CapturedMediaDetailSheet: View {
    let image: UIImage
    var modeName: String
    var stackedCount: Int
    var rejectedCount: Int
    var totalExposure: Float
    var isRedMode: Bool
    var onDismiss: () -> Void

    @State private var isSaving = false
    @State private var hasSaved = false
    @State private var isShowingShareSheet = false

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.165, blue: 0.294) : Color(red: 0.0, green: 0.898, blue: 1.0)
    }

    var cardBg: Color {
        Color(red: 20/255.0, green: 25/255.0, blue: 38/255.0)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 14) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("✨ KẾT QUẢ CHỒNG ẢNH SAO")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accentColor)

                        Text("\(modeName) • Đã phơi sáng \(Int(totalExposure)) giây")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Text("✕")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                    }
                }
                .padding(.horizontal, 4)

                // High-Res Image View
                ZStack {
                    Color.black
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                .frame(maxHeight: 380)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

                // 3 Statistics Chips
                HStack(spacing: 12) {
                    statChip(title: "ĐÃ CHỒNG", value: "\(stackedCount) ảnh", color: Color(red: 0.0, green: 0.902, blue: 0.463))
                    statChip(title: "LOẠI BỎ", value: "\(rejectedCount) ảnh", color: Color(red: 1.0, green: 0.67, blue: 0.0))
                    statChip(title: "TỔNG SÁNG", value: "\(Int(totalExposure))s", color: accentColor)
                }

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        guard !isSaving && !hasSaved else { return }
                        isSaving = true
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        PhotoLibraryExporter.saveImageToPhotoLibrary(image) { success, _ in
                            DispatchQueue.main.async {
                                isSaving = false
                                if success {
                                    hasSaved = true
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                Text("Đang lưu...")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                            } else {
                                Text(hasSaved ? "✓ Đã Lưu Gallery" : "💾 Lưu Vào Thư Viện")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(accentColor)
                        .cornerRadius(12)
                    }

                    Button(action: onDismiss) {
                        Text("Tiếp Tục")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentColor.opacity(0.6), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 10/255.0, green: 14/255.0, blue: 23/255.0, opacity: 0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(accentColor.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
        }
    }

    private func statChip(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(cardBg)
        .cornerRadius(8)
    }
}
