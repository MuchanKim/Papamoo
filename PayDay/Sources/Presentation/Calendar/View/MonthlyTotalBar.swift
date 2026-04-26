import SwiftUI

struct MonthlyTotalBar: View {
    let monthName: String
    let total: Decimal

    var body: some View {
        HStack {
            Text("\(monthName) total")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(total, format: .currency(code: "KRW").precision(.fractionLength(0)))
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
}
