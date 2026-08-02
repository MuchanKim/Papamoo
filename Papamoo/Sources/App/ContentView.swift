import SwiftUI

struct ContentView: View {

    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase
    @Bindable var coordinator: AppCoordinator
    let appContainer: AppContainer
    private let lifecycleSynchronizer: AppLifecycleSynchronizer
    @State private var homeViewModel: HomeViewModel
    @State private var calendarViewModel: CalendarViewModel
    @State private var settingsViewModel: SettingsViewModel
    @State private var synchronizationErrorMessage = ""
    @State private var isShowingSynchronizationError = false

    init(coordinator: AppCoordinator, appContainer: AppContainer) {
        self.coordinator = coordinator
        self.appContainer = appContainer
        self.lifecycleSynchronizer = appContainer.makeAppLifecycleSynchronizer()
        // 탭 전환 때 화면 모델을 다시 만들면 저장소 구독이 끊겨 빈 상태가 보일 수 있어 view identity에 묶어 유지한다.
        _homeViewModel = State(wrappedValue: appContainer.makeHomeViewModel())
        _calendarViewModel = State(wrappedValue: appContainer.makeCalendarViewModel())
        _settingsViewModel = State(wrappedValue: appContainer.makeSettingsViewModel())
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab("My Subs", systemImage: "creditcard.fill", value: .home) {
                HomeView(
                    coordinator: coordinator,
                    viewModel: homeViewModel,
                    appContainer: appContainer
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
                try await lifecycleSynchronizer.synchronizeOnActivation()
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

    // MARK: - Private Methods

    private func synchronizeVisibleData() {
        do {
            try lifecycleSynchronizer.synchronizeAfterStoreChange()
        } catch {
            synchronizationErrorMessage = error.localizedDescription
            isShowingSynchronizationError = true
        }
    }

    private func synchronizeWidgetSnapshot() {
        do {
            try lifecycleSynchronizer.synchronizeWidgetSnapshot()
        } catch {
            synchronizationErrorMessage = error.localizedDescription
            isShowingSynchronizationError = true
        }
    }
}
