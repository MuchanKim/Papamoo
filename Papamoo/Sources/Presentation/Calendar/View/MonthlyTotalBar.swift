import SwiftUI

struct MonthlyTotalBar: View {

    let monthName: String
    let total: Decimal
    let currencyCode: String

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(PapamooColor.dividerSoft).frame(height: 1)
            HStack(alignment: .firstTextBaseline) {
                Text(monthName.uppercased())
                    .font(.papamooMeta)
                    .foregroundStyle(PapamooColor.textMuted)
                    .tracking(1.0)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(CurrencyFormatter.amountString(total, currencyCode: currencyCode))
                        .font(.papamooMono(26, weight: .bold))
                        .foregroundStyle(PapamooColor.text)
                        .monospacedDigit()
                    Text(currencyCode)
                        .font(.papamooMono(11, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(PapamooColor.accent)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            Rectangle().fill(PapamooColor.dividerSoft).frame(height: 1)
        }
    }
}
