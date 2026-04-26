import Foundation

@Observable
final class SettingsViewModel {
    var isRemindOneDayBefore: Bool {
        get { UserDefaults.standard.object(forKey: "isRemindOneDayBefore") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isRemindOneDayBefore") }
    }

    var isRemindThreeDaysBefore: Bool {
        get { UserDefaults.standard.bool(forKey: "isRemindThreeDaysBefore") }
        set { UserDefaults.standard.set(newValue, forKey: "isRemindThreeDaysBefore") }
    }

    var notificationHour: Int {
        get {
            let val = UserDefaults.standard.object(forKey: "notificationHour") as? Int
            return val ?? 9
        }
        set { UserDefaults.standard.set(newValue, forKey: "notificationHour") }
    }

    var currencyCode: String {
        get { UserDefaults.standard.string(forKey: "currencyCode") ?? "KRW" }
        set { UserDefaults.standard.set(newValue, forKey: "currencyCode") }
    }

    var weekStartsOnMonday: Bool {
        get {
            let val = UserDefaults.standard.object(forKey: "weekStartsOnMonday") as? Bool
            return val ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: "weekStartsOnMonday") }
    }

    var appLanguage: String {
        get { UserDefaults.standard.string(forKey: "appLanguage") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "appLanguage") }
    }

    let supportedCurrencies = ["KRW", "USD", "JPY"]

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

    func currencyDisplayName(for code: String) -> String {
        switch code {
        case "KRW": "KRW (₩)"
        case "USD": "USD ($)"
        case "JPY": "JPY (¥)"
        default: code
        }
    }
}
