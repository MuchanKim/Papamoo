import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                preferencesSection
                languageSection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert(
                Text(verbatim: alertTitle),
                isPresented: $viewModel.showRestartAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(verbatim: alertMessage)
            }
        }
    }

    /// Bundle for the language the user just picked — the running process is still on the previous locale,
    /// so the restart alert needs to be looked up explicitly against the chosen language.
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
        alertBundle.localizedString(forKey: "Please restart PayDay to apply the new language.", value: nil, table: nil)
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: $viewModel.isRemindOneDayBefore) {
                Label("Notify D-1 before payment", systemImage: "bell.fill")
            }
            Toggle(isOn: $viewModel.isRemindThreeDaysBefore) {
                Label("Notify D-3 before payment", systemImage: "bell.fill")
            }
            DatePicker(
                selection: $viewModel.notificationTime,
                displayedComponents: .hourAndMinute
            ) {
                Label("Time", systemImage: "clock")
            }
        }
        .tint(PayDayColor.accent)
    }

    private var preferencesSection: some View {
        @Bindable var exchangeRate = ExchangeRateManager.shared
        return Section("Preferences") {
            Picker(selection: $exchangeRate.baseCurrency) {
                ForEach(exchangeRate.supportedCurrencies, id: \.self) { code in
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
            Link(destination: URL(string: "https://apps.apple.com")!) {
                Label("Rate the app", systemImage: "heart.fill")
            }
            Link(destination: URL(string: "mailto:hello@moolab.io?subject=PayDay%20문의")!) {
                Label("Contact support", systemImage: "envelope.fill")
            }
        }
    }
}
