import SwiftUI

struct SubscriptionRow: View {

    let subscription: Subscription
    let baseCurrency: String
    var showDday: Bool = false

    private var displayAmount: Decimal {
        ExchangeRateManager.shared.convertToBase(amount: subscription.amount, from: subscription.currencyCode)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: subscription.nextPaymentDate)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ServiceIconView(
                category: subscription.category,
                iconName: subscription.iconName,
                size: 40
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PapamooColor.text)
                Text(dateString)
                    .font(.papamooDate)
                    .foregroundStyle(PapamooColor.textMuted)
                    .tracking(0.4)
            }
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(CurrencyFormatter.amountString(displayAmount, currencyCode: baseCurrency))
                        .font(.papamooMono(20, weight: .bold))
                        .foregroundStyle(PapamooColor.text)
                        .monospacedDigit()
                    Text(baseCurrency)
                        .font(.papamooMono(10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(PapamooColor.accent)
                }
                if showDday {
                    Text("D-\(subscription.daysUntilNextPayment)")
                        .font(.papamooMono(10, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(PapamooColor.background)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(PapamooColor.accent, in: RoundedRectangle(cornerRadius: 5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(PapamooColor.surface, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
