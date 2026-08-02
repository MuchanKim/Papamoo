import SwiftUI

struct ShareNoteFieldView: View {

    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)

            TextField(
                "Optional. Add a note for context — e.g., shared with family, promo until Dec.",
                text: $note,
                axis: .vertical
            )
            .lineLimit(4...)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(ShareColor.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
