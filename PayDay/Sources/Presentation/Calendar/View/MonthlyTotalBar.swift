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
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(currencySymbol(for: currencyCode))
                        .font(.payDayMono(20, weight: .bold))
                        .foregroundStyle(PayDayColor.accent)
                    Text(amountString(total))
                        .font(.payDayMono(20, weight: .bold))
                        .foregroundStyle(PayDayColor.text)
                        .monospacedDigit()
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            Rectangle().fill(PayDayColor.dividerSoft).frame(height: 1)
        }
    }

    private func currencySymbol(for code: String) -> String {
        switch code {
        case "KRW": "₩"
        case "USD": "$"
        case "JPY": "¥"
        default: code
        }
    }

    private func amountString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(for: value) ?? "0"
    }
}
