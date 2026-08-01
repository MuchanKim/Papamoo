import SwiftUI

struct ShareRootView: View {
    @Bindable var viewModel: ShareImportViewModel

    var body: some View {
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
            case .saved:
                ShareSavedView()
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
        .alert("Couldn’t save the subscription", isPresented: $viewModel.isShowingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your information is still here. Please try saving again.")
        }
    }
}
