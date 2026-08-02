import SwiftUI

struct ShareLoadingView: View {

    @Bindable var viewModel: ShareImportViewModel

    var body: some View {
        VStack(spacing: 16) {
            ShareGrabberView()
            ShareBrandHeaderView(closeAction: viewModel.cancel)

            Spacer()

            ProgressView()
                .tint(ShareColor.accent)
                .controlSize(.large)

            Text("Loading your image")
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }
}
