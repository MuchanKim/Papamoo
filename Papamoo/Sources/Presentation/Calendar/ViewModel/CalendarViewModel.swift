import Foundation
import SwiftData

@Observable
final class CalendarViewModel {
    private let context: ModelContext
    private let exchangeRate = ExchangeRateManager.shared
    private(set) var subscriptions: [Subscription] = []
    private(set) var fetchErrorMessage = ""
    var isShowingFetchError = false
    var displayedMonth: Int
    var displayedYear: Int
    var selectedDay: Int?

    init(context: ModelContext) {
        self.context = context
        self.displayedMonth = Calendar.current.component(.month, from: .now)
        self.displayedYear = Calendar.current.component(.year, from: .now)
    }

    var baseCurrency: String { exchangeRate.baseCurrency }

    /// 선택된 일자의 결제 합계 (base currency 환산).
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

    private func paymentDateInDisplayedMonth(for sub: Subscription) -> Date? {
        let calendar = Calendar.current
        let next = sub.nextPaymentDate
        if calendar.component(.month, from: next) == displayedMonth,
           calendar.component(.year, from: next) == displayedYear {
            return next
        }
        let cycle: Calendar.Component = sub.billingCycle == .monthly ? .month : .year
        guard let last = calendar.date(byAdding: cycle, value: -1, to: next),
              last >= calendar.startOfDay(for: sub.firstPaymentDate) else { return nil }
        if calendar.component(.month, from: last) == displayedMonth,
           calendar.component(.year, from: last) == displayedYear {
            return last
        }
        return nil
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

    func changeMonth(by value: Int) {
        var components = DateComponents(year: displayedYear, month: displayedMonth)
        components.month! += value
        let date = Calendar.current.date(from: components)!
        displayedMonth = Calendar.current.component(.month, from: date)
        displayedYear = Calendar.current.component(.year, from: date)
        selectedDay = nil
    }
}
