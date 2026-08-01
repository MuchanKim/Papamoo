import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    private let context: ModelContext
    private(set) var subscriptions: [Subscription] = []
    private(set) var fetchErrorMessage = ""
    var isShowingFetchError = false

    init(context: ModelContext) {
        self.context = context
    }

    var sortedByNextPayment: [Subscription] {
        subscriptions.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
    }

    private let exchangeRate = ExchangeRateManager.shared

    /// 기준 통화 코드.
    var baseCurrency: String { exchangeRate.baseCurrency }

    var monthlyTotal: Decimal {
        paidThisMonth + remainingThisMonth
    }

    /// 이번 달 이미 결제된 금액 (기준 통화 환산).
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

    func fetch() {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\Subscription.firstPaymentDate)]
        )
        do {
            subscriptions = try context.fetch(descriptor)
            isShowingFetchError = false
        } catch {
            fetchErrorMessage = error.localizedDescription
            isShowingFetchError = true
        }
    }

    func removeSubscription(withID id: PersistentIdentifier) {
        subscriptions.removeAll { $0.persistentModelID == id }
    }

    private func hasUpcomingBillingThisMonth(_ sub: Subscription) -> Bool {
        Calendar.current.isDate(sub.nextPaymentDate, equalTo: .now, toGranularity: .month)
    }

    private func hasPaidBillingThisMonth(_ sub: Subscription) -> Bool {
        let calendar = Calendar.current
        let cycle: Calendar.Component = sub.billingCycle == .monthly ? .month : .year
        guard let lastPayment = calendar.date(byAdding: cycle, value: -1, to: sub.nextPaymentDate),
              lastPayment >= calendar.startOfDay(for: sub.firstPaymentDate) else {
            return false
        }
        return calendar.isDate(lastPayment, equalTo: .now, toGranularity: .month)
    }
}
