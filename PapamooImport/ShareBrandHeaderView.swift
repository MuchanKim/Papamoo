import SwiftUI

struct ShareBrandHeaderView: View {

    // MARK: - Callbacks

    let closeAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image("PapamooBrandIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)

            Text("Papamoo")
                .font(.title3)
                .bold()

            Spacer()

            Button("Close", systemImage: "xmark", action: closeAction)
                .labelStyle(.iconOnly)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(ShareColor.background, in: Circle())
                .overlay {
                    Circle().stroke(ShareColor.divider, lineWidth: 1)
                }
                .contentShape(.circle)
                .buttonStyle(.plain)
        }
    }
}
