import Foundation

enum LanguagePreference {
    static func apply(_ code: String) {
        // 실행 중인 Locale은 바뀌지 않으므로 AppleLanguages를 다음 cold launch용으로 동기화한다.
        if code == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
    }
}
