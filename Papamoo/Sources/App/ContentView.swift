import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var coordinator: AppCoordinator
    let factory: ViewModelFactory
    @State private var homeViewModel: HomeViewModel
    @State private var calendarViewModel: CalendarViewModel
    @State private var settingsViewModel: SettingsViewModel
    @State private var synchronizationErrorMessage = ""
    @State private var isShowingSynchronizationError = false

    init(coordinator: AppCoordinator, factory: ViewModelFactory) {
        self.coordinator = coordinator
        self.factory = factory
        // SwiftUI @State가 view identity 기반으로 인스턴스 lifecycle 관리.
        // factory에서 한 번 생성, 이후 탭 전환에도 같은 인스턴스 유지 → 빈 데이터 깜빡임 없음.
        _homeViewModel = State(wrappedValue: factory.makeHomeViewModel())
        _calendarViewModel = State(wrappedValue: factory.makeCalendarViewModel())
        _settingsViewModel = State(wrappedValue: factory.makeSettingsViewModel())
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab("My Subs", systemImage: "creditcard.fill", value: .home) {
                HomeView(
                    coordinator: coordinator,
                    viewModel: homeViewModel,
                    factory: factory
                )
            }
            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                CalendarView(viewModel: calendarViewModel)
            }
            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView(viewModel: settingsViewModel)
            }
        }
        .tint(PapamooColor.accent)
        .preferredColorScheme(.dark)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            do {
                try await factory.importPendingSubscriptions()
                homeViewModel.fetch()
                calendarViewModel.fetch()
                try factory.synchronizeWidgetSnapshot()
            } catch is CancellationError {
                return
            } catch {
                synchronizationErrorMessage = error.localizedDescription
                isShowingSynchronizationError = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionStoreDidChange)) { _ in
            synchronizeVisibleData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exchangeRateDidChange)) { _ in
            synchronizeWidgetSnapshot()
        }
        .alert("구독 정보를 새로 고치지 못했어요", isPresented: $isShowingSynchronizationError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(synchronizationErrorMessage)
        }
    }

    private func synchronizeVisibleData() {
        homeViewModel.fetch()
        calendarViewModel.fetch()
        synchronizeWidgetSnapshot()
    }

    private func synchronizeWidgetSnapshot() {
        do {
            try factory.synchronizeWidgetSnapshot()
        } catch {
            synchronizationErrorMessage = error.localizedDescription
            isShowingSynchronizationError = true
        }
    }
}
