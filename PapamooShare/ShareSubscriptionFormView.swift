import SwiftUI

struct ShareSubscriptionFormView: View {
    @Environment(\.locale) private var locale

    @Bindable var viewModel: ShareImportViewModel
    let mode: ShareImportFormMode

    var body: some View {
        @Bindable var form = viewModel.form

        VStack(spacing: 0) {
            ShareGrabberView()
                .padding(.top, 10)

            ShareFormNavigationBar(
                title: navigationTitle,
                backAction: viewModel.returnToReview
            )
            .padding(.horizontal, 12)

            Divider().overlay(ShareColor.divider)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if showsReviewBanner {
                        ShareAutoFillBanner(
                            mode: mode,
                            needsReviewFieldCount: viewModel.draft.needsReviewFieldCount
                        )
                        .padding(.bottom, 20)
                    }

                    ShareServiceHeaderView(
                        name: $form.name,
                        category: form.category,
                        iconName: viewModel.draft.iconName
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 4)

                        SharePlanFieldsView(
                            amountText: $form.amountText,
                            currencyCode: $form.currencyCode,
                            billingCycle: $form.billingCycle,
                            firstPaymentDate: $form.firstPaymentDate,
                            category: $form.category,
                            supportedCurrencies: form.supportedCurrencies
                        )
                    }

                    ShareNoteFieldView(note: $form.note)
                        .padding(.top, 20)

                    if let image = viewModel.previewImage {
                        ShareSourcePreviewView(
                            image: image,
                            isExpanded: $viewModel.showsSourceImage
                        )
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            addButton
        }
    }

    private var showsReviewBanner: Bool {
        mode != .complete && (mode != .manual || viewModel.previewImage != nil)
    }

    private var navigationTitle: String {
        guard viewModel.form.name.isEmpty else { return viewModel.form.name }
        let title: LocalizedStringResource = "New service"
        return String(localized: title.localized(for: locale))
    }

    private var addButtonTitle: LocalizedStringResource {
        if viewModel.isSaved {
            "SAVED"
        } else if viewModel.isSaving {
            "SAVING"
        } else {
            "ADD SUBSCRIPTION"
        }
    }

    private var addButton: some View {
        Button(action: viewModel.save) {
            HStack(spacing: 8) {
                if viewModel.isSaved {
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                        .transition(.scale.combined(with: .opacity))
                } else if viewModel.isSaving {
                    ProgressView()
                        .tint(ShareColor.background)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(addButtonTitle.localized(for: locale))
                    .contentTransition(.opacity)
            }
            .font(.papamooMono(13, weight: .bold))
            .tracking(1)
            .foregroundStyle(ShareColor.background)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                viewModel.form.isValid ? ShareColor.accent : Color.secondary,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .disabled(viewModel.form.isValid == false || viewModel.isSaving || viewModel.isSaved)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSaving)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSaved)
        .accessibilityHint("Save the subscription information and close this screen.")
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}
