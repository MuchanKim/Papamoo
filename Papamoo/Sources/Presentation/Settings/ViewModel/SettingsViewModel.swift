import Foundation
import SwiftData

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
            NotificationManager.rescheduleAll(in: modelContext)
        }
    }

    var isRemindThreeDaysBefore: Bool {
        didSet {
            UserDefaults.appGroup.set(isRemindThreeDaysBefore, forKey: "isRemindThreeDaysBefore")
            NotificationManager.rescheduleAll(in: modelContext)
        }
    }

    var notificationHour: Int {
        didSet {
            UserDefaults.appGroup.set(notificationHour, forKey: "notificationHour")
            NotificationManager.rescheduleAll(in: modelContext)
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
}
