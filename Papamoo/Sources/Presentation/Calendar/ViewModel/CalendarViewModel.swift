import Foundation
import SwiftData

@Observable
final class CalendarViewModel {
    private let context: ModelContext
    private let exchangeRate = ExchangeRateManager.shared
    private(set) var subscriptions: [Subscription] = []
    var displayedMonth: Int
    var displayedYear: Int
    var selectedDay: Int?

    init(context: ModelContext) {
        self.context = context
        self.displayedMonth = Calendar.current.component(.month, from: .now)
        self.displayedYear = Calendar.current.component(.year, from: .now)
    }

    var baseCurrency: String { exchangeRate.baseCurrency }

    /// 가장 가까운 다음 결제. countdown hero 표시용.
    var nextPayment: Subscription? {
        subscriptions.sorted { $0.nextPaymentDate < $1.nextPaymentDate }.first
    }

    /// 가장 가까운 결제의 base currency 환산 금액.
    var nextPaymentDisplayAmount: Decimal {
        guard let next = nextPayment else { return 0 }
        return exchangeRate.convertToBase(amount: next.amount, from: next.currencyCode)
    }

    /// 선택된 일자의 결제 합계 (base currency 환산).
    var selectedDayTotal: Decimal {
        selectedDaySubscriptions.reduce(Decimal.zero) { total, sub in
            total + exchangeRate.convertToBase(amount: sub.amount, from: sub.currencyCode)
        }
    }

    var eventDates: [Int: [SubscriptionCategory]] {
        var result: [Int: [SubscriptionCategory]] = [:]
        for sub in subscriptions {
            let nextDate = sub.nextPaymentDate
            let calendar = Calendar.current
            let month = calendar.component(.month, from: nextDate)
            let year = calendar.component(.year, from: nextDate)
            if month == displayedMonth && year == displayedYear {
                let day = calendar.component(.day, from: nextDate)
                result[day, default: []].append(sub.category)
            }
        }
        return result
    }

    var selectedDaySubscriptions: [Subscription] {
        guard let selectedDay else { return [] }
        return subscriptions.filter { sub in
            let calendar = Calendar.current
            let nextDate = sub.nextPaymentDate
            return calendar.component(.day, from: nextDate) == selectedDay
                && calendar.component(.month, from: nextDate) == displayedMonth
                && calendar.component(.year, from: nextDate) == displayedYear
        }
    }

    var monthTotal: Decimal {
        subscriptions
            .filter { sub in
                let calendar = Calendar.current
                let nextDate = sub.nextPaymentDate
                return calendar.component(.month, from: nextDate) == displayedMonth
                    && calendar.component(.year, from: nextDate) == displayedYear
            }
            .reduce(0) { total, sub in
                total + exchangeRate.convertToBase(amount: sub.amount, from: sub.currencyCode)
            }
    }

    func fetch() {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\Subscription.firstPaymentDate)]
        )
        subscriptions = (try? context.fetch(descriptor)) ?? []
    }

    func changeMonth(by value: Int) {
        var components = DateComponents(year: displayedYear, month: displayedMonth)
        components.month! += value
        let date = Calendar.current.date(from: components)!
        displayedMonth = Calendar.current.component(.month, from: date)
        displayedYear = Calendar.current.component(.year, from: date)
        selectedDay = nil
    }
}
