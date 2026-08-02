import Foundation

@Observable
final class CalendarViewModel {

    // MARK: - Properties

    private let subscriptionStore: SubscriptionStore
    private let exchangeRate = ExchangeRateManager.shared
    var displayedMonth: Int
    var displayedYear: Int
    var selectedDay: Int?

    init(subscriptionStore: SubscriptionStore) {
        self.subscriptionStore = subscriptionStore
        self.displayedMonth = Calendar.current.component(.month, from: .now)
        self.displayedYear = Calendar.current.component(.year, from: .now)
        self.selectedDay = Calendar.current.component(.day, from: .now)
    }

    var baseCurrency: String { exchangeRate.baseCurrency }

    private var subscriptions: [Subscription] {
        subscriptionStore.subscriptions
    }

    var selectedDayTotal: Decimal {
        selectedDaySubscriptions.reduce(Decimal.zero) { total, sub in
            total + exchangeRate.convertToBase(amount: sub.amount, from: sub.currencyCode)
        }
    }

    var dailyTotals: [Int: Decimal] {
        var result: [Int: Decimal] = [:]
        let calendar = Calendar.current
        for sub in subscriptions {
            guard let date = paymentDateInDisplayedMonth(for: sub) else { continue }
            let day = calendar.component(.day, from: date)
            result[day, default: .zero] += exchangeRate.convertToBase(
                amount: sub.amount,
                from: sub.currencyCode
            )
        }
        return result
    }

    var monthPaymentCount: Int {
        subscriptions.count { paymentDateInDisplayedMonth(for: $0) != nil }
    }

    var selectedDaySubscriptions: [Subscription] {
        guard let selectedDay else { return [] }
        let calendar = Calendar.current
        return subscriptions.filter { sub in
            guard let date = paymentDateInDisplayedMonth(for: sub) else { return false }
            return calendar.component(.day, from: date) == selectedDay
        }
    }

    var monthTotal: Decimal {
        dailyTotals.values.reduce(.zero, +)
    }

    var selectedDate: Date? {
        guard let selectedDay else { return nil }
        return Calendar.current.date(
            from: DateComponents(
                year: displayedYear,
                month: displayedMonth,
                day: selectedDay
            )
        )
    }

    // MARK: - Methods

    func changeMonth(by value: Int) {
        var components = DateComponents(year: displayedYear, month: displayedMonth)
        components.month! += value
        let date = Calendar.current.date(from: components)!
        displayedMonth = Calendar.current.component(.month, from: date)
        displayedYear = Calendar.current.component(.year, from: date)
        selectedDay = nil
    }

    // MARK: - Private Methods

    private func paymentDateInDisplayedMonth(for sub: Subscription) -> Date? {
        sub.billingSchedule.paymentDate(
            inMonth: displayedMonth,
            year: displayedYear
        )
    }
}
