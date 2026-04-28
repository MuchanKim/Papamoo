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
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(
                    displayAmount,
                    format: .currency(code: baseCurrency)
                        .presentation(.narrow)
                        .precision(.fractionLength(0))
                )
                .font(.payDayAmount)
                .foregroundStyle(PayDayColor.text)
                .monospacedDigit()
                if showDday {
                    Text("D-\(subscription.daysUntilNextPayment)")
                        .font(.payDayMeta)
                        .foregroundStyle(PayDayColor.accent)
                        .tracking(0.3)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}
