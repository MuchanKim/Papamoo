import Foundation

enum ShareLanguagePreference {
    private static let languageKey = "appLanguage"

    static var currentLocale: Locale {
        guard let code = UserDefaults(suiteName: AppGroup.identifier)?.string(forKey: languageKey),
              code != "system"
        else {
            return .autoupdatingCurrent
        }

        return Locale(identifier: code)
    }
}
