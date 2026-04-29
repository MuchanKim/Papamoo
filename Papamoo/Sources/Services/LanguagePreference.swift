import Foundation

/// AppleLanguages UserDefaults override 책임. 다음 cold launch에 반영.
enum LanguagePreference {
    static func apply(_ code: String) {
        if code == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
    }
}
