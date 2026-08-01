import SwiftUI

struct ShareAutoFillBanner: View {
    @Environment(\.locale) private var locale

    let mode: ShareImportFormMode
    let needsReviewFieldCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: mode == .complete ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(ShareColor.accent)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.localized(for: locale))
                    .font(.subheadline.bold())

                Text(message.localized(for: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(ShareColor.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var message: LocalizedStringResource {
        switch mode {
        case .complete:
            "Review the auto-filled information before saving."
        case .partial:
            needsReviewFieldCount > 0
                ? "Review the information that needs confirmation before saving."
                : "Fill in the required information before saving."
        case .manual:
            "Enter the required payment information."
        }
    }

    private var title: LocalizedStringResource {
        if mode == .complete {
            return "Payment information is ready"
        }
        return needsReviewFieldCount > 0 ? "Some information needs review" : "Some information is missing"
    }
}
