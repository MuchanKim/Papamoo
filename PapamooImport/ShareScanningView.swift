import SwiftUI

struct ShareScanningView: View {

    @Bindable var viewModel: ShareImportViewModel

    var body: some View {
        VStack(spacing: 16) {
            ShareGrabberView()
            ShareBrandHeaderView(closeAction: viewModel.cancel)

            Spacer()

            VStack(spacing: 8) {
                ProgressView()
                    .tint(ShareColor.accent)
                    .controlSize(.large)
                    .accessibilityHidden(true)
                Text("Finding payment information")
                    .font(.title3.bold())
                Text("Checking the service, amount, and payment date.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .accessibilityElement(children: .combine)
    }
}
