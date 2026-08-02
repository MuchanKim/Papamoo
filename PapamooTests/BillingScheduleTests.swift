import Foundation
import Testing
@testable import Papamoo

@MainActor
struct BillingScheduleTests {

    // MARK: - Methods

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

    @Test("현재 날짜와 관계없이 표시 월의 결제일을 반환한다")
    func paymentDateInDisplayedMonth() throws {
        let calendar = makeCalendar()
        let startDate = try makeDate(year: 2026, month: 1, day: 15, calendar: calendar)
        let junePayment = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let julyPayment = try makeDate(year: 2026, month: 7, day: 15, calendar: calendar)
        let augustPayment = try makeDate(year: 2026, month: 8, day: 15, calendar: calendar)
        let schedule = BillingSchedule(firstPaymentDate: startDate, billingCycle: .monthly)

        #expect(schedule.paymentDate(
            inMonth: 6,
            year: 2026,
            calendar: calendar
        ) == junePayment)
        #expect(schedule.paymentDate(
            inMonth: 7,
            year: 2026,
            calendar: calendar
        ) == julyPayment)
        #expect(schedule.paymentDate(
            inMonth: 8,
            year: 2026,
            calendar: calendar
        ) == augustPayment)
        #expect(schedule.paymentDate(
            inMonth: 12,
            year: 2025,
            calendar: calendar
        ) == nil)
    }

    @Test("월말 첫 결제일 당일을 직전 결제일로 유지한다")
    func preservesEndOfMonthFirstPaymentAsPreviousPayment() throws {
        let calendar = makeCalendar()
        let firstPaymentDate = try makeDate(year: 2026, month: 1, day: 31, calendar: calendar)
        let expectedNextPayment = try makeDate(year: 2026, month: 2, day: 28, calendar: calendar)
        let schedule = BillingSchedule(
            firstPaymentDate: firstPaymentDate,
            billingCycle: .monthly
        )

        #expect(schedule.previousPaymentDate(
            relativeTo: firstPaymentDate,
            calendar: calendar
        ) == firstPaymentDate)
        #expect(schedule.nextPaymentDate(
            relativeTo: firstPaymentDate,
            calendar: calendar
        ) == expectedNextPayment)
        #expect(schedule.paymentDate(
            inMonth: 1,
            year: 2026,
            calendar: calendar
        ) == firstPaymentDate)
    }

    @Test("월말 결제일은 짧은 달 이후에도 최초 일자를 기준으로 복원된다")
    func restoresEndOfMonthAnchorAfterShortMonth() throws {
        let calendar = makeCalendar()
        let firstPaymentDate = try makeDate(year: 2026, month: 1, day: 31, calendar: calendar)
        let referenceDate = try makeDate(year: 2026, month: 3, day: 1, calendar: calendar)
        let expectedPreviousPayment = try makeDate(year: 2026, month: 2, day: 28, calendar: calendar)
        let expectedNextPayment = try makeDate(year: 2026, month: 3, day: 31, calendar: calendar)
        let schedule = BillingSchedule(
            firstPaymentDate: firstPaymentDate,
            billingCycle: .monthly
        )

        #expect(schedule.previousPaymentDate(
            relativeTo: referenceDate,
            calendar: calendar
        ) == expectedPreviousPayment)
        #expect(schedule.nextPaymentDate(
            relativeTo: referenceDate,
            calendar: calendar
        ) == expectedNextPayment)
    }

    @Test("윤일 첫 결제일 당일을 연간 직전 결제일로 유지한다")
    func preservesLeapDayFirstPaymentAsPreviousPayment() throws {
        let calendar = makeCalendar()
        let firstPaymentDate = try makeDate(year: 2024, month: 2, day: 29, calendar: calendar)
        let expectedNextPayment = try makeDate(year: 2025, month: 2, day: 28, calendar: calendar)
        let schedule = BillingSchedule(
            firstPaymentDate: firstPaymentDate,
            billingCycle: .yearly
        )

        #expect(schedule.previousPaymentDate(
            relativeTo: firstPaymentDate,
            calendar: calendar
        ) == firstPaymentDate)
        #expect(schedule.nextPaymentDate(
            relativeTo: firstPaymentDate,
            calendar: calendar
        ) == expectedNextPayment)
    }

    @Test("윤일 결제일은 다음 윤년에 2월 29일로 복원된다")
    func restoresLeapDayAnchorInNextLeapYear() throws {
        let calendar = makeCalendar()
        let firstPaymentDate = try makeDate(year: 2024, month: 2, day: 29, calendar: calendar)
        let referenceDate = try makeDate(year: 2028, month: 2, day: 1, calendar: calendar)
        let expectedPreviousPayment = try makeDate(year: 2027, month: 2, day: 28, calendar: calendar)
        let expectedNextPayment = try makeDate(year: 2028, month: 2, day: 29, calendar: calendar)
        let schedule = BillingSchedule(
            firstPaymentDate: firstPaymentDate,
            billingCycle: .yearly
        )

        #expect(schedule.previousPaymentDate(
            relativeTo: referenceDate,
            calendar: calendar
        ) == expectedPreviousPayment)
        #expect(schedule.nextPaymentDate(
            relativeTo: referenceDate,
            calendar: calendar
        ) == expectedNextPayment)
    }

    // MARK: - Private Methods

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
