import Testing
import Foundation
@testable import Papamoo

struct SubscriptionTests {
    @Test func nextPaymentDateFutureStart() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: .now)!
        let sub = Subscription(name: "Test", amount: 10000, firstPaymentDate: futureDate)
        let expected = Calendar.current.startOfDay(for: futureDate)
        #expect(Calendar.current.startOfDay(for: sub.nextPaymentDate) == expected)
    }

    @Test func nextPaymentDatePastStart() {
        let pastDate = Calendar.current.date(byAdding: .month, value: -3, to: .now)!
        let sub = Subscription(name: "Test", amount: 10000, firstPaymentDate: pastDate)
        #expect(sub.nextPaymentDate > .now || Calendar.current.isDateInToday(sub.nextPaymentDate))
    }

    @Test func daysUntilNextPayment() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        let sub = Subscription(name: "Test", amount: 10000, firstPaymentDate: futureDate)
        #expect(sub.daysUntilNextPayment == 5)
    }

    @Test func monthlyAmountForYearly() {
        let sub = Subscription(name: "Test", amount: 120000, billingCycle: .yearly, firstPaymentDate: .now)
        #expect(sub.monthlyAmount == 10000)
    }

    @Test func presetServicesNotEmpty() {
        #expect(!PresetService.all.isEmpty)
    }

    @Test func presetServicesHaveAllCategories() {
        let categories = Set(PresetService.all.map(\.category))
        #expect(categories.contains(.streaming))
        #expect(categories.contains(.ai))
        #expect(categories.contains(.productivity))
    }

    @Test func notificationDateUsesConfiguredHourBeforeFilteringPastDates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let nextPaymentDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 29,
            hour: 0
        ))!
        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 28,
            hour: 12
        ))!

        let notificationDate = NotificationManager.notificationDate(
            for: nextPaymentDate,
            daysBefore: 1,
            hour: 21,
            calendar: calendar,
            now: now
        )

        #expect(notificationDate == calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 28,
            hour: 21,
            minute: 0,
            second: 0
        )))
    }

    @Test func notificationDateRejectsConfiguredFireDateInThePast() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let nextPaymentDate = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 29,
            hour: 0
        ))!
        let now = calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 28,
            hour: 12
        ))!

        let notificationDate = NotificationManager.notificationDate(
            for: nextPaymentDate,
            daysBefore: 1,
            hour: 9,
            calendar: calendar,
            now: now
        )

        #expect(notificationDate == nil)
    }
}
