import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct CalendarViewModelTests {

    // MARK: - Methods

    @Test("표시 중인 월의 날짜별 합계와 결제 건수를 계산한다")
    func calculatesDailyTotalsAndPaymentCount() throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "papamoo-calendar-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(
            "CalendarViewModelTests",
            schema: schema,
            url: directory.appending(path: "subscriptions.store"),
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Subscription.self, configurations: configuration)
        let context = container.mainContext
        let paymentDate = Calendar.current.date(byAdding: .day, value: 5, to: .now)!

        context.insert(makeSubscription(name: "First", amount: 4_900, date: paymentDate))
        context.insert(makeSubscription(name: "Second", amount: 10_000, date: paymentDate))
        try context.save()

        let subscriptionStore = SubscriptionStore(context: context)
        try subscriptionStore.refresh()
        let viewModel = CalendarViewModel(subscriptionStore: subscriptionStore)
        #expect(viewModel.selectedDay == Calendar.current.component(.day, from: .now))
        viewModel.displayedYear = Calendar.current.component(.year, from: paymentDate)
        viewModel.displayedMonth = Calendar.current.component(.month, from: paymentDate)
        let day = Calendar.current.component(.day, from: paymentDate)
        #expect(viewModel.dailyTotals[day] == 14_900)
        #expect(viewModel.monthTotal == 14_900)
        #expect(viewModel.monthPaymentCount == 2)

        viewModel.selectedDay = day
        #expect(viewModel.selectedDayTotal == 14_900)
        #expect(viewModel.selectedDaySubscriptions.count == 2)
        #expect(viewModel.selectedDate.map { Calendar.current.component(.day, from: $0) } == day)
    }

    @Test("현재 월에서 떨어진 표시 월도 결제 내역을 계산한다")
    func calculatesPaymentsForArbitraryDisplayedMonth() throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "papamoo-calendar-arbitrary-month-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(
            "CalendarViewModelTests",
            schema: schema,
            url: directory.appending(path: "subscriptions.store"),
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Subscription.self, configurations: configuration)
        let context = container.mainContext
        let firstPaymentDate = try #require(Calendar.current.date(
            from: DateComponents(year: 2024, month: 1, day: 15)
        ))

        context.insert(makeSubscription(name: "Monthly", amount: 4_900, date: firstPaymentDate))
        try context.save()

        let subscriptionStore = SubscriptionStore(context: context)
        try subscriptionStore.refresh()
        let viewModel = CalendarViewModel(subscriptionStore: subscriptionStore)
        viewModel.displayedYear = 2026
        viewModel.displayedMonth = 6

        #expect(viewModel.dailyTotals[15] == 4_900)
        #expect(viewModel.monthPaymentCount == 1)
    }

    // MARK: - Private Methods

    private func makeSubscription(name: String, amount: Decimal, date: Date) -> Subscription {
        Subscription(
            name: name,
            amount: amount,
            currencyCode: ExchangeRateManager.shared.baseCurrency,
            firstPaymentDate: date
        )
    }
}
