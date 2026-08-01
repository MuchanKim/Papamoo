import SwiftUI

struct ShareSavedView: View {
    var body: some View {
        VStack(spacing: 18) {
            ShareGrabberView()
                .padding(.top, 10)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(ShareColor.background)
                .frame(width: 64, height: 64)
                .background(ShareColor.accent, in: Circle())
                .accessibilityHidden(true)

            Text("Saved")
                .font(.title2.bold())

            Text("It will appear in your subscriptions when Papamoo opens.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
