import SwiftUI

struct ShareCropView: View {

    // MARK: - Properties

    @Bindable var viewModel: ShareImportViewModel
    @State private var selection: CGRect

    init(viewModel: ShareImportViewModel) {
        self.viewModel = viewModel
        _selection = State(
            initialValue: viewModel.cropRegion ?? CGRect(x: 0.08, y: 0.08, width: 0.84, height: 0.84)
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            ShareGrabberView()

            HStack {
                Button("Back", systemImage: "chevron.left", action: viewModel.leaveCrop)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)

                Spacer()

                Text("Select payment area")
                    .font(.headline)

                Spacer()

                Button("Done", action: applyCrop)
                    .bold()
                    .foregroundStyle(ShareColor.accent)
                    .frame(minWidth: 44, minHeight: 44)
            }

            if let image = viewModel.previewImage {
                ShareCropCanvasView(image: image, selection: $selection)
                    .frame(maxHeight: .infinity)
            }

            VStack(spacing: 6) {
                Text("Keep only the payment information you need.")
                    .font(.subheadline)
                Text("DRAG CORNERS · PINCH TO ZOOM")
                    .font(.shareMeta)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }

    // MARK: - Private Methods

    private func applyCrop() {
        viewModel.applyCrop(selection)
    }
}
