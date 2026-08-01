import Foundation

nonisolated struct BillingSchedule: Sendable {
    let firstPaymentDate: Date
    let billingCycle: BillingCycle

    func nextPaymentDate(
        relativeTo referenceDate: Date,
        calendar: Calendar = .current
    ) -> Date {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let startDay = calendar.startOfDay(for: firstPaymentDate)
        guard startDay <= referenceDay else { return startDay }

        var candidate = startDay
        while candidate <= referenceDay {
            guard let next = calendar.date(
                byAdding: billingCycle.calendarComponent,
                value: 1,
                to: candidate
            ) else {
                return candidate
            }
            candidate = next
        }
        return candidate
    }

    func previousPaymentDate(
        relativeTo referenceDate: Date,
        calendar: Calendar = .current
    ) -> Date? {
        let startDay = calendar.startOfDay(for: firstPaymentDate)
        let nextPayment = nextPaymentDate(relativeTo: referenceDate, calendar: calendar)
        guard let previousPayment = calendar.date(
            byAdding: billingCycle.calendarComponent,
            value: -1,
            to: nextPayment
        ), previousPayment >= startDay else {
            return nil
        }
        return previousPayment
    }

    func paymentDate(
        inMonth month: Int,
        year: Int,
        relativeTo referenceDate: Date,
        calendar: Calendar = .current
    ) -> Date? {
        let nextPayment = nextPaymentDate(relativeTo: referenceDate, calendar: calendar)
        if calendar.component(.month, from: nextPayment) == month,
           calendar.component(.year, from: nextPayment) == year {
            return nextPayment
        }

        guard let previousPayment = previousPaymentDate(
            relativeTo: referenceDate,
            calendar: calendar
        ), calendar.component(.month, from: previousPayment) == month,
           calendar.component(.year, from: previousPayment) == year else {
            return nil
        }
        return previousPayment
    }

    func daysUntilNextPayment(
        relativeTo referenceDate: Date,
        calendar: Calendar = .current
    ) -> Int {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let nextPayment = nextPaymentDate(relativeTo: referenceDate, calendar: calendar)
        return calendar.dateComponents([.day], from: referenceDay, to: nextPayment).day ?? 0
    }
}

private extension BillingCycle {
    nonisolated var calendarComponent: Calendar.Component {
        switch self {
        case .monthly: .month
        case .yearly: .year
        }
    }
}
