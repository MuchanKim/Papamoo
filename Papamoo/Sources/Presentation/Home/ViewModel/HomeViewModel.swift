import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    private let context: ModelContext
    private(set) var subscriptions: [Subscription] = []

    init(context: ModelContext) {
        self.context = context
    }

    var sortedByNextPayment: [Subscription] {
        subscriptions.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
    }

    private let exchangeRate = ExchangeRateManager.shared

    /// 기준 통화 코드.
    var baseCurrency: String { exchangeRate.baseCurrency }

    /// 모든 구독의 월간 총액 (기준 통화 환산).
    var monthlyTotal: Decimal {
        subscriptions.reduce(0) { total, sub in
            total + exchangeRate.convertToBase(amount: sub.monthlyAmount, from: sub.currencyCode)
        }
    }

    /// 이번 달 이미 결제된 금액 (기준 통화 환산).
    var paidThisMonth: Decimal {
        let calendar = Calendar.current
        let now = Date.now
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        return subscriptions
            .filter { sub in
                let next = sub.nextPaymentDate
                let nextMonth = calendar.component(.month, from: next)
                let nextYear = calendar.component(.year, from: next)
                return nextYear > currentYear || (nextYear == currentYear && nextMonth > currentMonth)
            }
            .reduce(0) { total, sub in
                total + exchangeRate.convertToBase(amount: sub.amount, from: sub.currencyCode)
            }
    }

    var remainingThisMonth: Decimal {
        monthlyTotal - paidThisMonth
    }

    var upcomingSubscriptions: [Subscription] {
        sortedByNextPayment
    }

    func fetch() {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\Subscription.firstPaymentDate)]
        )
        subscriptions = (try? context.fetch(descriptor)) ?? []
    }
}
