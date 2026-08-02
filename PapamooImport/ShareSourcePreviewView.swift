import SwiftUI

struct ShareSourcePreviewView: View {

    let image: UIImage
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup("View source document", isExpanded: $isExpanded) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 240)
                .background(ShareColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 10)
                .accessibilityLabel("Source payment document from share")
        }
        .font(.subheadline.bold())
        .tint(ShareColor.accent)
        .padding(14)
        .background(ShareColor.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
    }
}
