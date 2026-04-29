import SwiftUI

struct ServiceIconView: View {
    let category: SubscriptionCategory
    var iconName: String? = nil
    var size: CGFloat = 40

    private var cornerRadius: CGFloat {
        size * 0.225
    }

    var body: some View {
        if let iconName, let uiImage = UIImage(named: iconName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.tertiarySystemFill))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: category.iconSystemName)
                        .font(.system(size: size * 0.35, weight: .medium))
                        .foregroundStyle(.secondary)
                }
        }
    }
}
