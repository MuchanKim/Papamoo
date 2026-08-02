import SwiftUI

struct SourceDocumentImageView: View {

    let data: Data

    @State private var image: CGImage?
    @State private var didFinishLoading = false

    var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("공유에서 가져온 원본 결제 문서")
            } else if didFinishLoading {
                ContentUnavailableView(
                    "원본 문서를 표시할 수 없어요",
                    systemImage: "photo.badge.exclamationmark"
                )
            } else {
                ProgressView("원본 문서를 불러오는 중")
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .task {
            image = await SourceDocumentImageDecoder.decode(data)
            didFinishLoading = true
        }
    }
}
