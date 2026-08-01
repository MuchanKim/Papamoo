import Foundation
import Testing
@testable import Papamoo

struct NotificationManagerTests {
    @Test(
        "오늘의 설정 시각이 미래면 알림 시각을 반환한다",
        .bug("https://github.com/MuchanKim/Papamoo/issues/2")
    )
    func keepsConfiguredTimeLaterToday() throws {
        let calendar = try utcCalendar()
        let nextPaymentDate = try date(
            year: 2026,
            month: 8,
            day: 2,
            hour: 0,
            calendar: calendar
        )
        let now = try date(
            year: 2026,
            month: 8,
            day: 1,
            hour: 12,
            calendar: calendar
        )

        let result = NotificationManager.notificationDate(
            for: nextPaymentDate,
            daysBefore: 1,
            hour: 21,
            calendar: calendar,
            now: now
        )

        let expected = try date(
            year: 2026,
            month: 8,
            day: 1,
            hour: 21,
            calendar: calendar
        )
        #expect(result == expected)
    }

    @Test(
        "오늘의 설정 시각이 지났으면 알림을 예약하지 않는다",
        .bug("https://github.com/MuchanKim/Papamoo/issues/2")
    )
    func rejectsConfiguredTimeEarlierToday() throws {
        let calendar = try utcCalendar()
        let nextPaymentDate = try date(
            year: 2026,
            month: 8,
            day: 2,
            hour: 0,
            calendar: calendar
        )
        let now = try date(
            year: 2026,
            month: 8,
            day: 1,
            hour: 12,
            calendar: calendar
        )

        let result = NotificationManager.notificationDate(
            for: nextPaymentDate,
            daysBefore: 1,
            hour: 9,
            calendar: calendar,
            now: now
        )

        #expect(result == nil)
    }

    private func utcCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        return calendar
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        calendar: Calendar
    ) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: 0,
            second: 0
        )))
    }
}
