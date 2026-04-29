import SwiftUI

/// Navigation 상태만 보유. ViewModel 생성은 ViewModelFactory가 담당.
@Observable
final class AppCoordinator {
    enum Tab { case home, calendar, settings }

    var selectedTab: Tab = .home
    var isShowingAddSheet = false
    var selectedSubscription: Subscription?

    func showAddSubscription() {
        isShowingAddSheet = true
    }

    func dismissAddSubscription() {
        isShowingAddSheet = false
    }

    func selectSubscription(_ subscription: Subscription) {
        selectedSubscription = subscription
    }
}
