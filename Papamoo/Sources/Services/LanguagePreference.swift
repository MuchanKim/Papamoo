import Foundation

enum LanguagePreference {
    static let defaultSelection = "system"
    static let fallbackLanguageCode = "en"

    static func apply(_ code: String) {
        // 시스템 선택은 번들 언어 결정을 따르며, 미지원 언어는 개발 언어인 영어로 폴백한다.
        if code == defaultSelection {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
    }
}
