import SwiftUI

/// Băng chuyền chuyển đổi các chế độ chụp ảnh/quay video (Mode Carousel)
struct ModeCarousel: View {
    @Binding var selectedMode: AppCameraMode
    var isRedMode: Bool
    var isDisabled: Bool

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.16, blue: 0.29) : Color.yellow
    }

    var body: some View {
        HStack(spacing: 22) {
            ForEach(AppCameraMode.allCases) { mode in
                let isSelected = (mode == selectedMode)
                Button(action: {
                    guard !isDisabled else { return }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMode = mode
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(mode.displayName)
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? accentColor : .white.opacity(0.6))
                            .tracking(0.5)

                        // Dấu chấm tròn phát sáng khi chế độ được chọn
                        Circle()
                            .fill(isSelected ? accentColor : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isDisabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.45))
        .clipShape(Capsule())
    }
}
