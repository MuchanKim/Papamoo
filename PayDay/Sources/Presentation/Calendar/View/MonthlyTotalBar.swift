import SwiftUI

struct MonthlyTotalBar: View {
    let monthName: String
    let total: Decimal
    let currencyCode: String

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(PayDayColor.dividerSoft).frame(height: 1)
            HStack(alignment: .firstTextBaseline) {
                Text(monthName.uppercased())
                    .font(.payDayMeta)
                    .foregroundStyle(PayDayColor.textMuted)
                    .tracking(1.0)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(CurrencyFormatter.amountString(total))
                        .font(.payDayMono(26, weight: .bold))
                        .foregroundStyle(PayDayColor.text)
                        .monospacedDigit()
                    Text(currencyCode)
                        .font(.payDayMono(11, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(PayDayColor.accent)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            Rectangle().fill(PayDayColor.dividerSoft).frame(height: 1)
        }
    }
}
