import SwiftUI
import SwiftData

@Observable
final class AppCoordinator {
    enum Tab { case home, calendar, settings }

    var selectedTab: Tab = .home
    var isShowingAddSheet = false
    var selectedSubscription: Subscription?

    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(context: modelContext)
    }

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(context: modelContext)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel()
    }

    func makeAddSubscriptionViewModel() -> AddSubscriptionViewModel {
        AddSubscriptionViewModel(context: modelContext)
    }

    func showAddSubscription() {
        isShowingAddSheet = true
    }

    func dismissAddSubscription() {
        isShowingAddSheet = false
    }

    func selectSubscription(_ subscription: Subscription) {
        selectedSubscription = subscription
    }

    func dismissSubscriptionDetail() {
        selectedSubscription = nil
    }
}
