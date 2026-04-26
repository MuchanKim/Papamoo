import SwiftUI

struct ContentView: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab("My Subs", systemImage: "creditcard.fill", value: .home) {
                HomeView(
                    coordinator: coordinator,
                    viewModel: coordinator.makeHomeViewModel()
                )
            }
            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                CalendarView(viewModel: coordinator.makeCalendarViewModel())
            }
            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView(viewModel: coordinator.makeSettingsViewModel())
            }
        }
        .tint(.white)
        .preferredColorScheme(.dark)
    }
}
