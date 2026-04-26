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
        }
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
        .tint(PayDayColor.brand)
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Picker(selection: $viewModel.currencyCode) {
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
            Link(destination: URL(string: "https://apps.apple.com")!) {
                Label("Rate the app", systemImage: "heart.fill")
            }
            Link(destination: URL(string: "mailto:devmutopia@gmail.com")!) {
                Label("Contact support", systemImage: "envelope.fill")
            }
        }
    }
}
