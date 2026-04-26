import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription
    var showDday: Bool = false

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
            Text(subscription.amount, format: .currency(code: subscription.currencyCode).precision(.fractionLength(0)))
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
