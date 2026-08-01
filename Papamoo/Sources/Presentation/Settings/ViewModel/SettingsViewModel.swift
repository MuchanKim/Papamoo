import Foundation
import SwiftData
import UserNotifications

@Observable
final class SettingsViewModel {
    private let modelContext: ModelContext
    private let exchangeRate = ExchangeRateManager.shared

    var baseCurrency: String {
        get { exchangeRate.baseCurrency }
        set { exchangeRate.baseCurrency = newValue }
    }

    var supportedCurrencies: [String] { exchangeRate.supportedCurrencies }

    var isRemindOneDayBefore: Bool {
        didSet {
            UserDefaults.appGroup.set(isRemindOneDayBefore, forKey: "isRemindOneDayBefore")
            rescheduleNotifications()
        }
    }

    var isRemindThreeDaysBefore: Bool {
        didSet {
            UserDefaults.appGroup.set(isRemindThreeDaysBefore, forKey: "isRemindThreeDaysBefore")
            rescheduleNotifications()
        }
    }

    var notificationHour: Int {
        didSet {
            UserDefaults.appGroup.set(notificationHour, forKey: "notificationHour")
            rescheduleNotifications()
        }
    }

    var weekStartsOnMonday: Bool {
        didSet { UserDefaults.appGroup.set(weekStartsOnMonday, forKey: "weekStartsOnMonday") }
    }

    var appLanguage: String {
        didSet {
            UserDefaults.appGroup.set(appLanguage, forKey: "appLanguage")
            LanguagePreference.apply(appLanguage)
            showRestartAlert = true
        }
    }

    var showRestartAlert: Bool = false
    var isShowingNotificationSchedulingError = false
    private(set) var notificationSchedulingErrorMessage = ""
    private(set) var notificationAuthorizationState: NotificationAuthorizationState = .loading
    private(set) var isRequestingNotificationAuthorization = false

    var notificationTime: Date {
        get {
            var components = DateComponents()
            components.hour = notificationHour
            components.minute = 0
            return Calendar.current.date(from: components) ?? .now
        }
        set {
            notificationHour = Calendar.current.component(.hour, from: newValue)
        }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let defaults = UserDefaults.appGroup
        self.isRemindOneDayBefore = defaults.object(forKey: "isRemindOneDayBefore") as? Bool ?? true
        self.isRemindThreeDaysBefore = defaults.bool(forKey: "isRemindThreeDaysBefore")
        self.notificationHour = defaults.object(forKey: "notificationHour") as? Int ?? 9
        self.weekStartsOnMonday = defaults.object(forKey: "weekStartsOnMonday") as? Bool ?? true
        self.appLanguage = defaults.string(forKey: "appLanguage") ?? "system"
    }

    func currencyDisplayName(for code: String) -> String {
        switch code {
        case "KRW": "KRW (₩)"
        case "USD": "USD ($)"
        case "JPY": "JPY (¥)"
        default: code
        }
    }

    func refreshNotificationAuthorizationState() async {
        let status = await NotificationManager.authorizationStatus()
        notificationAuthorizationState = NotificationAuthorizationState(status: status)
    }

    func requestNotificationAuthorization() async {
        guard isRequestingNotificationAuthorization == false else { return }
        isRequestingNotificationAuthorization = true
        defer { isRequestingNotificationAuthorization = false }

        do {
            let isAuthorized = try await NotificationManager.requestAuthorization()
            await refreshNotificationAuthorizationState()
            guard isAuthorized else { return }
            try NotificationManager.rescheduleAll(in: modelContext)
            isShowingNotificationSchedulingError = false
        } catch is CancellationError {
            return
        } catch {
            notificationSchedulingErrorMessage = error.localizedDescription
            isShowingNotificationSchedulingError = true
        }
    }

    private func rescheduleNotifications() {
        do {
            try NotificationManager.rescheduleAll(in: modelContext)
            isShowingNotificationSchedulingError = false
        } catch {
            notificationSchedulingErrorMessage = error.localizedDescription
            isShowingNotificationSchedulingError = true
        }
    }
}
