import Foundation
import SwiftData
import WidgetKit

final class WidgetSnapshotSynchronizer {
    private let context: ModelContext
    private let store: WidgetSnapshotStore
    private let exchangeRate: ExchangeRateManager

    init(
        context: ModelContext,
        store: WidgetSnapshotStore,
        exchangeRate: ExchangeRateManager = .shared
    ) {
        self.context = context
        self.store = store
        self.exchangeRate = exchangeRate
    }

    func synchronize(now: Date = .now, calendar: Calendar = .current) throws {
        let subscriptions = try context.fetch(FetchDescriptor<Subscription>())
        let upcoming = subscriptions
            .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
            .prefix(4)
            .map {
                WidgetSubscriptionSnapshot(
                    name: $0.name,
                    category: $0.category.rawValue,
                    amount: $0.amount,
                    currencyCode: $0.currencyCode,
                    nextPaymentDate: $0.nextPaymentDate,
                    daysUntil: $0.daysUntilNextPayment
                )
            }

        let paid = subscriptions
            .filter { hasPaidBillingThisMonth($0, now: now, calendar: calendar) }
            .reduce(Decimal.zero) {
                $0 + exchangeRate.convertToBase(amount: $1.amount, from: $1.currencyCode)
            }
        let remaining = subscriptions
            .filter { calendar.isDate($0.nextPaymentDate, equalTo: now, toGranularity: .month) }
            .reduce(Decimal.zero) {
                $0 + exchangeRate.convertToBase(amount: $1.amount, from: $1.currencyCode)
            }

        try store.save(
            WidgetSnapshot(
                generatedAt: now,
                subscriptions: Array(upcoming),
                monthlyTotal: paid + remaining,
                remainingThisMonth: remaining,
                totalCount: subscriptions.count,
                baseCurrency: exchangeRate.baseCurrency
            )
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func hasPaidBillingThisMonth(
        _ subscription: Subscription,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard let lastPayment = subscription.billingSchedule.previousPaymentDate(
            relativeTo: now,
            calendar: calendar
        ) else {
            return false
        }
        return calendar.isDate(lastPayment, equalTo: now, toGranularity: .month)
    }
}

extension Notification.Name {
    static let subscriptionStoreDidChange = Notification.Name("subscriptionStoreDidChange")
    static let exchangeRateDidChange = Notification.Name("exchangeRateDidChange")
}
