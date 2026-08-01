import SwiftUI

struct ShareServiceHeaderView: View {
    @Environment(\.locale) private var locale

    @Binding var name: String
    let category: SubscriptionCategory
    let iconName: String?

    var body: some View {
        VStack(spacing: 10) {
            ServiceIconView(category: category, iconName: iconName, size: 72)
                .accessibilityHidden(true)

            TextField("Service name", text: $name)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)

            Text(category.displayName.localized(for: locale))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 20)
    }
}
