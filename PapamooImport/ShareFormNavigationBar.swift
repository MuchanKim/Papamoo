import SwiftUI

struct ShareFormNavigationBar: View {

    // MARK: - Properties

    let title: String

    // MARK: - Callbacks

    let backAction: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .padding(.horizontal, 52)

            HStack {
                Button("Back", systemImage: "chevron.left", action: backAction)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)

                Spacer()
            }
        }
        .frame(minHeight: 44)
    }
}
