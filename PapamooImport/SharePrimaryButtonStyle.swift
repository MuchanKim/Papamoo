import SwiftUI

struct SharePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.papamooMono(13, weight: .bold))
            .tracking(1)
            .foregroundStyle(ShareColor.background)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(ShareColor.accent, in: RoundedRectangle(cornerRadius: 12))
            .contentShape(.rect)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
