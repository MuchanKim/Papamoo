import SwiftUI

struct ShareReviewView: View {

    @Bindable var viewModel: ShareImportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShareGrabberView()
                .frame(maxWidth: .infinity)
            ShareBrandHeaderView(closeAction: viewModel.cancel)

            if let image = viewModel.selectedPreviewImage {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(ShareColor.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("Shared payment image")

                    Button("Select payment area", systemImage: "crop", action: viewModel.beginCrop)
                        .labelStyle(.iconOnly)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(ShareColor.accent)
                        .frame(width: 44, height: 44)
                        .background(ShareColor.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ShareColor.divider, lineWidth: 1)
                        }
                        .contentShape(.rect)
                        .buttonStyle(.plain)
                        .padding(8)
                }
                .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Papamoo will read your payment information")
                    .font(.title2)
                    .bold()
                Text("You can review and edit the information before saving.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("GET SUBSCRIPTION INFO", action: viewModel.startRecognition)
                .buttonStyle(SharePrimaryButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
}
