import SwiftUI

/// 미세한 shadow가 적용된 공통 카드 컨테이너.
struct CardView<Content: View>: View {
    var cornerRadius: CGFloat = 14
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(.background, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
    }
}
