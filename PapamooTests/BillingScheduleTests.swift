import Foundation
import Testing
@testable import Papamoo

@MainActor
struct BillingScheduleTests {
    @Test("시작일이 미래면 시작일을 다음 결제일로 반환한다")
    func futureStartDateIsNextPaymentDate() throws {
        let calendar = makeCalendar()
        let startDate = try makeDate(year: 2026, month: 8, day: 20, calendar: calendar)
        let referenceDate = try makeDate(year: 2026, month: 8, day: 1, calendar: calendar)
        let schedule = BillingSchedule(firstPaymentDate: startDate, billingCycle: .monthly)

        let result = schedule.nextPaymentDate(relativeTo: referenceDate, calendar: calendar)

        #expect(result == startDate)
        #expect(schedule.previousPaymentDate(relativeTo: referenceDate, calendar: calendar) == nil)
    }

    @Test("월간 구독의 다음 결제일과 직전 결제일을 계산한다")
    func monthlyPaymentDates() throws {
        let calendar = makeCalendar()
        let startDate = try makeDate(year: 2026, month: 1, day: 15, calendar: calendar)
        let referenceDate = try makeDate(year: 2026, month: 8, day: 1, calendar: calendar)
        let expectedPrevious = try makeDate(year: 2026, month: 7, day: 15, calendar: calendar)
        let expectedNext = try makeDate(year: 2026, month: 8, day: 15, calendar: calendar)
        let schedule = BillingSchedule(firstPaymentDate: startDate, billingCycle: .monthly)

        #expect(schedule.nextPaymentDate(relativeTo: referenceDate, calendar: calendar) == expectedNext)
        #expect(schedule.previousPaymentDate(relativeTo: referenceDate, calendar: calendar) == expectedPrevious)
        #expect(schedule.daysUntilNextPayment(relativeTo: referenceDate, calendar: calendar) == 14)
    }

    @Test("연간 구독의 다음 결제일과 직전 결제일을 계산한다")
    func yearlyPaymentDates() throws {
        let calendar = makeCalendar()
        let startDate = try makeDate(year: 2024, month: 5, day: 10, calendar: calendar)
        let referenceDate = try makeDate(year: 2026, month: 8, day: 1, calendar: calendar)
        let expectedPrevious = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
        let expectedNext = try makeDate(year: 2027, month: 5, day: 10, calendar: calendar)
        let schedule = BillingSchedule(firstPaymentDate: startDate, billingCycle: .yearly)

        #expect(schedule.nextPaymentDate(relativeTo: referenceDate, calendar: calendar) == expectedNext)
        #expect(schedule.previousPaymentDate(relativeTo: referenceDate, calendar: calendar) == expectedPrevious)
    }

    @Test("표시 월이 다음 또는 직전 결제 월일 때 결제일을 반환한다")
    func paymentDateInDisplayedMonth() throws {
        let calendar = makeCalendar()
        let startDate = try makeDate(year: 2026, month: 1, day: 15, calendar: calendar)
        let referenceDate = try makeDate(year: 2026, month: 8, day: 1, calendar: calendar)
        let julyPayment = try makeDate(year: 2026, month: 7, day: 15, calendar: calendar)
        let augustPayment = try makeDate(year: 2026, month: 8, day: 15, calendar: calendar)
        let schedule = BillingSchedule(firstPaymentDate: startDate, billingCycle: .monthly)

        #expect(schedule.paymentDate(
            inMonth: 7,
            year: 2026,
            relativeTo: referenceDate,
            calendar: calendar
        ) == julyPayment)
        #expect(schedule.paymentDate(
            inMonth: 8,
            year: 2026,
            relativeTo: referenceDate,
            calendar: calendar
        ) == augustPayment)
        #expect(schedule.paymentDate(
            inMonth: 6,
            year: 2026,
            relativeTo: referenceDate,
            calendar: calendar
        ) == nil)
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        calendar: Calendar
    ) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }
}
