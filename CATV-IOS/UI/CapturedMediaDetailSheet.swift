import SwiftUI

/// Hộp thoại xem chi tiết ảnh chụp hoặc kết quả phơi sáng thiên văn kèm chia sẻ
struct CapturedMediaDetailSheet: View {
    let image: UIImage
    var modeName: String
    var stackedCount: Int
    var rejectedCount: Int
    var totalExposure: Float
    var isRedMode: Bool
    var onDismiss: () -> Void

    @State private var isShowingShareSheet = false
    @State private var saveSuccessMessage: String?

    var accentColor: Color {
        isRedMode ? Color.red : Color(red: 0.0, green: 0.9, blue: 1.0)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    // 1. Ảnh hiển thị chính
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)

                    // 2. Thống kê chi tiết
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Chế độ:")
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(modeName)
                                .bold()
                                .foregroundColor(accentColor)
                        }

                        if stackedCount > 0 {
                            HStack {
                                Text("Khung đã chồng:")
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("\(stackedCount) khung (loại \(rejectedCount))")
                                    .bold()
                                    .foregroundColor(.white)
                            }

                            HStack {
                                Text("Tổng thời gian tích lũy:")
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(String(format: "%.1f giây", totalExposure))
                                    .bold()
                                    .foregroundColor(.yellow)
                            }
                        }

                        if let msg = saveSuccessMessage {
                            Text(msg)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 4)
                        }
                    }
                    .font(.system(size: 13))
                    .padding()
                    .background(Color(white: 0.12))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // 3. Các nút thao tác
                    HStack(spacing: 16) {
                        // Nút lưu lại
                        Button(action: {
                            PhotoLibraryExporter.saveImageToPhotoLibrary(image) { success, _ in
                                if success {
                                    saveSuccessMessage = "✅ Đã lưu vào Thư viện Ảnh!"
                                }
                            }
                        }) {
                            Label("Lưu vào Photos", systemImage: "square.and.arrow.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(accentColor)
                                .cornerRadius(10)
                        }

                        // Nút chia sẻ
                        Button(action: {
                            isShowingShareSheet = true
                        }) {
                            Label("Chia sẻ", systemImage: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 8)
            }
            .navigationTitle("Xem kết quả")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        onDismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                ShareSheet(activityItems: [image])
            }
        }
    }
}

/// Helper wrapper cho UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
