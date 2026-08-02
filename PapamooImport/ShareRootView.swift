import SwiftUI

struct ShareRootView: View {

    @State private var viewModel: ShareImportViewModel

    init(viewModel: ShareImportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            switch viewModel.phase {
            case .loading:
                ShareLoadingView(viewModel: viewModel)
            case .review:
                ShareReviewView(viewModel: viewModel)
            case .crop:
                ShareCropView(viewModel: viewModel)
            case .preparingCrop:
                SharePreparingCropView(cancelAction: viewModel.cancel)
            case .scanning:
                ShareScanningView(viewModel: viewModel)
            case let .form(mode):
                ShareSubscriptionFormView(viewModel: viewModel, mode: mode)
            case let .failed(kind):
                ShareFailureView(viewModel: viewModel, kind: kind)
            }
        }
        .background(ShareColor.surface)
        .tint(ShareColor.accent)
        .environment(\.locale, ShareLanguagePreference.currentLocale)
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadInputIfNeeded()
        }
        .interactiveDismissDisabled(viewModel.preventsInteractiveDismissal)
        .onDisappear(perform: viewModel.stopWork)
        .alert("Couldn’t save the subscription", isPresented: $viewModel.isShowingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your information is still here. Please try saving again.")
        }
    }
}
