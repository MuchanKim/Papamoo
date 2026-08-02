import SwiftUI

struct SettingsView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                preferencesSection
                languageSection
                aboutSection
            }
            .tint(PapamooColor.text)
            .navigationTitle("Settings")
            .alert(
                Text(verbatim: alertTitle),
                isPresented: $viewModel.showRestartAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(verbatim: alertMessage)
            }
            .alert(
                "Couldn’t update notifications",
                isPresented: $viewModel.isShowingNotificationSchedulingError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.notificationSchedulingErrorMessage)
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                await viewModel.refreshNotificationAuthorizationState()
            }
        }
    }

    /// 실행 중인 Locale은 이전 언어이므로 재시작 안내만 사용자가 방금 고른 언어에서 직접 조회한다.
    private var alertBundle: Bundle {
        let code = viewModel.appLanguage
        guard code != "system",
              let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }

    private var alertTitle: String {
        alertBundle.localizedString(forKey: "Restart required", value: nil, table: nil)
    }

    private var alertMessage: String {
        alertBundle.localizedString(forKey: "Please restart Papamoo to apply the new language.", value: nil, table: nil)
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: $viewModel.isRemindOneDayBefore) {
                Label("Notify D-1 before payment", systemImage: "bell.fill")
            }
            .tint(PapamooColor.accent)
            Toggle(isOn: $viewModel.isRemindThreeDaysBefore) {
                Label("Notify D-3 before payment", systemImage: "bell.fill")
            }
            .tint(PapamooColor.accent)
            DatePicker(
                selection: $viewModel.notificationTime,
                displayedComponents: .hourAndMinute
            ) {
                Label("Time", systemImage: "clock")
            }
            NotificationAuthorizationRow(viewModel: viewModel)
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Picker(selection: $viewModel.baseCurrency) {
                ForEach(viewModel.supportedCurrencies, id: \.self) { code in
                    Text(viewModel.currencyDisplayName(for: code)).tag(code)
                }
            } label: {
                Label("Currency", systemImage: "wonsign")
            }
            Picker(selection: $viewModel.weekStartsOnMonday) {
                Text("Sunday").tag(false)
                Text("Monday").tag(true)
            } label: {
                Label("Week starts on", systemImage: "calendar")
            }
        }
    }

    private var languageSection: some View {
        Section("Language") {
            Picker(selection: $viewModel.appLanguage) {
                Text("System").tag("system")
                Text("English").tag("en")
                Text("한국어").tag("ko")
                Text("日本語").tag("ja")
            } label: {
                Label("App language", systemImage: "globe")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
            } label: {
                Label("Version", systemImage: "info.circle")
            }
            Link(destination: URL(string: "mailto:hello@moolab.io?subject=Papamoo%20문의")!) {
                Label("Contact support", systemImage: "envelope.fill")
            }
            Link(destination: URL(string: "https://www.exchangerate-api.com")!) {
                Label {
                    Text(verbatim: "Rates By Exchange Rate API")
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
            }
        }
    }
}
