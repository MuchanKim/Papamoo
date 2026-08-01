import SwiftUI

struct ShareCropHandleView: View {
    let corner: ShareCropCorner

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(ShareColor.accent)
            .frame(width: 18, height: 18)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .accessibilityLabel(corner.accessibilityLabel)
            .accessibilityHint("Drag to resize the payment information selection.")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
}
