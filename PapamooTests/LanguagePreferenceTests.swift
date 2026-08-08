import Foundation
import Testing
@testable import Papamoo

@MainActor
struct LanguagePreferenceTests {
    @Test("앱 언어의 기본 선택은 시스템 언어다")
    func defaultsToSystemLanguage() {
        #expect(LanguagePreference.defaultSelection == "system")
    }

    @Test("지원하지 않는 시스템 언어는 영어로 폴백한다")
    func fallsBackToEnglish() {
        #expect(LanguagePreference.fallbackLanguageCode == "en")
        #expect(Bundle.main.developmentLocalization == LanguagePreference.fallbackLanguageCode)
    }
}
