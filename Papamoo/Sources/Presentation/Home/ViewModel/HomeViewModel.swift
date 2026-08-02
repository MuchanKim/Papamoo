import Foundation
import SwiftData

@Observable
final class HomeViewModel {

    // MARK: - Properties

    private let subscriptionStore: SubscriptionStore
    private let subscriptionService: SubscriptionService

    init(
        subscriptionStore: SubscriptionStore,
        subscriptionService: SubscriptionService
    ) {
        self.subscriptionStore = subscriptionStore
        self.subscriptionService = subscriptionService
    }

    var subscriptions: [Subscription] {
        subscriptionStore.subscriptions
    }

    var sortedByNextPayment: [Subscription] {
        subscriptions.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
    }

    private let exchangeRate = ExchangeRateManager.shared

    var baseCurrency: String { exchangeRate.baseCurrency }

    var monthlyTotal: Decimal {
        paidThisMonth + remainingThisMonth
    }

    var paidThisMonth: Decimal {
        subscriptions
            .filter { hasPaidBillingThisMonth($0) }
            .reduce(0) { $0 + exchangeRate.convertToBase(amount: $1.amount, from: $1.currencyCode) }
    }

    var remainingThisMonth: Decimal {
        subscriptions
            .filter { hasUpcomingBillingThisMonth($0) }
            .reduce(0) { $0 + exchangeRate.convertToBase(amount: $1.amount, from: $1.currencyCode) }
    }

    var upcomingSubscriptions: [Subscription] {
        sortedByNextPayment
    }

    // MARK: - Methods

    func deleteSubscription(withID id: PersistentIdentifier) async throws {
        try await subscriptionService.delete(id: id)
    }

    // MARK: - Private Methods

    private func hasUpcomingBillingThisMonth(_ sub: Subscription) -> Bool {
        Calendar.current.isDate(sub.nextPaymentDate, equalTo: .now, toGranularity: .month)
    }

    private func hasPaidBillingThisMonth(_ sub: Subscription) -> Bool {
        let calendar = Calendar.current
        guard let lastPayment = sub.billingSchedule.previousPaymentDate(
            relativeTo: .now,
            calendar: calendar
        ) else {
            return false
        }
        return calendar.isDate(lastPayment, equalTo: .now, toGranularity: .month)
    }
}
