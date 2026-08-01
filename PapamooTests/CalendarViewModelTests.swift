import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct CalendarViewModelTests {
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

    private func makeSubscription(name: String, amount: Decimal, date: Date) -> Subscription {
        Subscription(
            name: name,
            amount: amount,
            currencyCode: ExchangeRateManager.shared.baseCurrency,
            firstPaymentDate: date
        )
    }
}
