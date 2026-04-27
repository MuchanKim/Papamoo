import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription
    let baseCurrency: String
    var showDday: Bool = false

    private var displayAmount: Decimal {
        ExchangeRateManager.shared.convertToBase(amount: subscription.amount, from: subscription.currencyCode)
    }

    var body: some View {
        HStack(spacing: 12) {
            ServiceIconView(category: subscription.category, iconName: subscription.iconName)

            subscriptionInfo

            Spacer()

            amountSection

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.quaternary)
        }
    }

    private var subscriptionInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subscription.name)
                .font(.body)
                .fontWeight(.medium)
            Text(subscription.nextPaymentDate, format: .dateTime.month(.abbreviated).day())
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var amountSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(displayAmount, format: .currency(code: baseCurrency).presentation(.narrow).precision(.fractionLength(0)))
                .font(.body)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(showDday ? PayDayColor.brand : .primary)

            if showDday {
                DdayBadge(days: subscription.daysUntilNextPayment)
            }
        }
    }
}
