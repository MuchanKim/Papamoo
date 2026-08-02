import Foundation

nonisolated struct BillingSchedule: Sendable {

    // MARK: - Properties

    let firstPaymentDate: Date
    let billingCycle: BillingCycle

    // MARK: - Methods

    func nextPaymentDate(
        relativeTo referenceDate: Date,
        calendar: Calendar = .current
    ) -> Date {
        paymentDates(relativeTo: referenceDate, calendar: calendar).next
    }

    func previousPaymentDate(
        relativeTo referenceDate: Date,
        calendar: Calendar = .current
    ) -> Date? {
        paymentDates(relativeTo: referenceDate, calendar: calendar).previous
    }

    func paymentDate(
        inMonth month: Int,
        year: Int,
        calendar: Calendar = .current
    ) -> Date? {
        guard let monthStart = calendar.date(
            from: DateComponents(year: year, month: month, day: 1)
        ), let previousDay = calendar.date(byAdding: .day, value: -1, to: monthStart) else {
            return nil
        }

        let paymentDate = nextPaymentDate(relativeTo: previousDay, calendar: calendar)
        guard calendar.isDate(paymentDate, equalTo: monthStart, toGranularity: .month) else {
            return nil
        }
        return paymentDate
    }

    func daysUntilNextPayment(
        relativeTo referenceDate: Date,
        calendar: Calendar = .current
    ) -> Int {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let nextPayment = nextPaymentDate(relativeTo: referenceDate, calendar: calendar)
        return calendar.dateComponents([.day], from: referenceDay, to: nextPayment).day ?? 0
    }

    // MARK: - Private Methods

    private func paymentDates(
        relativeTo referenceDate: Date,
        calendar: Calendar
    ) -> (previous: Date?, next: Date) {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let startDay = calendar.startOfDay(for: firstPaymentDate)
        guard startDay <= referenceDay else { return (nil, startDay) }

        var previous: Date?
        var candidate = startDay
        var occurrence = 0
        while candidate <= referenceDay {
            previous = candidate
            occurrence += 1
            guard let next = calendar.date(
                byAdding: billingCycle.calendarComponent,
                value: occurrence,
                to: startDay
            ), next > candidate else {
                return (previous, candidate)
            }
            candidate = next
        }
        return (previous, candidate)
    }
}

// MARK: - Extensions

private extension BillingCycle {
    nonisolated var calendarComponent: Calendar.Component {
        switch self {
        case .monthly: .month
        case .yearly: .year
        }
    }
}
