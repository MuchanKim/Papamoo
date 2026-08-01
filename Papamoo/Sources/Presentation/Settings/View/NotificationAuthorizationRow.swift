import SwiftUI
import UIKit

struct NotificationAuthorizationRow: View {
    let viewModel: SettingsViewModel

    var body: some View {
        switch viewModel.notificationAuthorizationState {
        case .loading:
            HStack {
                ProgressView()
                Text("Checking notification permission…")
                    .foregroundStyle(.secondary)
            }
        case .notDetermined:
            Button(
                "Allow Notifications",
                systemImage: "bell.badge",
                action: requestAuthorization
            )
            .disabled(viewModel.isRequestingNotificationAuthorization)
        case .authorized:
            Label("Notifications are enabled", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.secondary)
        case .denied:
            VStack(alignment: .leading) {
                Label("Notifications are turned off in System Settings", systemImage: "bell.slash")
                    .foregroundStyle(.secondary)
                if let notificationSettingsURL {
                    Link(destination: notificationSettingsURL) {
                        Label("Open Notification Settings", systemImage: "gear")
                    }
                } else {
                    Label("Notification settings are unavailable", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            }
        case .unavailable:
            Label("Notification permission status is unavailable", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        }
    }

    private var notificationSettingsURL: URL? {
        URL(string: UIApplication.openNotificationSettingsURLString)
    }

    private func requestAuthorization() {
        Task {
            await viewModel.requestNotificationAuthorization()
        }
    }
}
