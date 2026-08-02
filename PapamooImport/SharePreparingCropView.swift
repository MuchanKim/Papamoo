import SwiftUI

struct SharePreparingCropView: View {

    // MARK: - Callbacks

    let cancelAction: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ShareGrabberView()
            ShareBrandHeaderView(closeAction: cancelAction)

            Spacer()

            ProgressView()
                .controlSize(.large)
                .tint(ShareColor.accent)

            VStack(spacing: 8) {
                Text("Applying your selection")
                    .font(.title3.bold())
                Text("Preparing the preview.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .accessibilityElement(children: .combine)
    }
}
