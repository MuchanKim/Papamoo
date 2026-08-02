import SwiftUI

struct SubscriptionSourceDocumentView: View {

    let imageData: Data

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("원본 문서 보기", isExpanded: $isExpanded) {
            SourceDocumentImageView(data: imageData)
                .frame(maxHeight: 420)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 12)
        }
        .font(.subheadline.bold())
        .tint(PapamooColor.accent)
        .padding(16)
        .background(PapamooColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
}
