import SwiftUI

struct ShareFailureView: View {

    // MARK: - Properties

    @Environment(\.locale) private var locale

    @Bindable var viewModel: ShareImportViewModel
    let kind: ShareFailureKind

    var body: some View {
        VStack(spacing: 18) {
            ShareGrabberView()
            ShareBrandHeaderView(closeAction: viewModel.cancel)

            Spacer()

            Image(systemName: iconSystemName)
                .font(.system(size: 46))
                .foregroundStyle(ShareColor.accent)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title.localized(for: locale))
                    .font(.title2.bold())
                Text(message.localized(for: locale))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: primaryAction) {
                Text(primaryTitle.localized(for: locale))
                    .font(.headline)
                    .foregroundStyle(ShareColor.background)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(ShareColor.accent, in: RoundedRectangle(cornerRadius: 12))
            }

            Button(action: secondaryAction) {
                Text(secondaryTitle.localized(for: locale))
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }

    private var title: LocalizedStringResource {
        switch kind {
        case .insufficientData:
            "Couldn’t find enough payment information"
        case .rejected(.refund):
            "This is a refund"
        case .rejected(.failedPayment):
            "This isn’t a completed payment"
        case .rejected(.authorizationOnly):
            "Only payment authorization information was found"
        case .rejected(.unknown):
            "Couldn’t confirm that the payment was completed"
        case .rejected(.completedPayment):
            "Couldn’t find enough payment information"
        case .analysis:
            "Couldn’t analyze the payment information"
        case .imageLoad:
            "Couldn’t load the image"
        case .cropProcessing:
            "Couldn’t apply the selected area"
        }
    }

    private var message: LocalizedStringResource {
        switch kind {
        case .insufficientData:
            "Select the area again or enter the information manually."
        case .rejected(.refund):
            "This wasn’t added as a subscription payment. Choose another image or enter the information manually."
        case .rejected(.failedPayment):
            "Check that the email confirms a completed charge."
        case .rejected(.authorizationOnly):
            "Choose an email that confirms the charge was completed."
        case .rejected(.unknown), .rejected(.completedPayment):
            "Select an area that clearly shows the completed payment."
        case .analysis:
            "An error occurred during analysis. Try again or enter the information manually."
        case .imageLoad:
            "Try again or enter the subscription information manually."
        case .cropProcessing:
            "Select the area again or enter the subscription information manually."
        }
    }

    private var primaryTitle: LocalizedStringResource {
        switch kind {
        case .imageLoad:
            "Try again"
        case .analysis:
            "Try again"
        case .cropProcessing:
            "Select area again"
        case .insufficientData where viewModel.didAttemptCrop:
            "Enter manually"
        case .insufficientData:
            "Select area again"
        case .rejected:
            "Enter manually"
        }
    }

    private var secondaryTitle: LocalizedStringResource {
        switch kind {
        case .imageLoad, .analysis, .cropProcessing:
            "Enter manually"
        case .insufficientData where viewModel.didAttemptCrop:
            "Select area again"
        case .insufficientData:
            "Enter manually"
        case .rejected:
            "Select area again"
        }
    }

    // MARK: - Private Methods

    private func primaryAction() {
        switch kind {
        case .imageLoad:
            viewModel.retryImageLoad()
        case .analysis:
            viewModel.startRecognition()
        case .cropProcessing:
            viewModel.beginCrop()
        case .insufficientData where viewModel.didAttemptCrop:
            viewModel.enterManualMode()
        case .insufficientData:
            viewModel.retryCropAfterFailure()
        case .rejected:
            viewModel.enterManualMode()
        }
    }

    private func secondaryAction() {
        switch kind {
        case .imageLoad, .analysis, .cropProcessing:
            viewModel.enterManualMode()
        case .insufficientData where viewModel.didAttemptCrop:
            viewModel.retryCropAfterFailure()
        case .insufficientData:
            viewModel.enterManualMode()
        case .rejected:
            viewModel.retryCropAfterFailure()
        }
    }

    private var iconSystemName: String {
        switch kind {
        case .imageLoad:
            "photo.badge.exclamationmark"
        case .analysis:
            "exclamationmark.triangle"
        case .cropProcessing:
            "crop"
        case .rejected(.refund):
            "arrow.uturn.backward.circle"
        case .rejected:
            "creditcard.trianglebadge.exclamationmark"
        case .insufficientData:
            "text.viewfinder"
        }
    }
}
