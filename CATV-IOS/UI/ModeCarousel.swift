import SwiftUI

/// Băng chuyền chuyển đổi chế độ máy ảnh chuẩn phong cách Android Camera
struct ModeCarousel: View {
    @Binding var selectedMode: AppCameraMode
    var isRedMode: Bool
    var isDisabled: Bool

    var accentColor: Color {
        isRedMode ? Color(red: 1.0, green: 0.165, blue: 0.294) : Color(red: 1.0, green: 0.839, blue: 0.0)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                ForEach(AppCameraMode.allCases) { mode in
                    let isSelected = (mode == selectedMode)
                    Button(action: {
                        guard !isDisabled else { return }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                    }) {
                        VStack(spacing: 3) {
                            Text(mode.title)
                                .font(.system(size: isSelected ? 14 : 13, weight: isSelected ? .bold : .normal))
                                .foregroundColor(isSelected ? accentColor : .white.opacity(0.6))

                            if isSelected {
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 4, height: 4)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                    .disabled(isDisabled)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.5))
    }
}
