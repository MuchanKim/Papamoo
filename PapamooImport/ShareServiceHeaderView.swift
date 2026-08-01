import SwiftUI

struct ShareServiceHeaderView: View {
    @Environment(\.locale) private var locale

    @Binding var name: String
    let category: SubscriptionCategory
    let iconName: String?

    var body: some View {
        VStack(spacing: 10) {
            ShareServiceIconView(category: category, iconName: iconName)
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

private struct ShareServiceIconView: View {
    let category: SubscriptionCategory
    let iconName: String?

    var body: some View {
        if let iconName, let image = UIImage(named: iconName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: category.iconSystemName)
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(.secondary)
                }
        }
    }
}
