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
                    .foregroundStyle(PayDayColor.text)
                Text(dateString)
                    .font(.payDayDate)
                    .foregroundStyle(PayDayColor.textMuted)
                    .tracking(0.4)
            }
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(CurrencyFormatter.amountString(displayAmount))
                        .font(.payDayAmount)
                        .foregroundStyle(PayDayColor.text)
                        .monospacedDigit()
                    Text(baseCurrency)
                        .font(.payDayMono(10, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(PayDayColor.accent)
                }
                if showDday {
                    Text("D-\(subscription.daysUntilNextPayment)")
                        .font(.payDayMono(10, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(PayDayColor.background)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(PayDayColor.accent, in: RoundedRectangle(cornerRadius: 5))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}
