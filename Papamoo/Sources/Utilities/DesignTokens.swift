import SwiftUI

/// 앱 전역에서 사용하는 디자인 토큰 (brutalist mono).
enum PapamooColor {
    /// 메인 화면 배경 (거의 검정).
    static let background = Color(red: 0.039, green: 0.039, blue: 0.039) // #0A0A0A

    /// 카드/리스트 row surface — background보다 살짝 밝은 회색.
    static let surface = Color(red: 0.078, green: 0.078, blue: 0.078) // #141414

    /// 주요 텍스트.
    static let text = Color.white

    /// 보조/메타 텍스트, dimmed 일자.
    static let textMuted = Color(red: 0.322, green: 0.322, blue: 0.322) // #525252

    /// 더 약한 보조 텍스트.
    static let textSubtle = Color(red: 0.451, green: 0.451, blue: 0.451) // #737373

    /// 단일 강조 색 (오늘, currency symbol, ruler, D-day 태그 등).
    static let accent = Color(red: 0.980, green: 0.800, blue: 0.082) // #FACC15

    /// 노랑 굵은 ruler (2pt).
    static let ruler = accent

    /// 미세 separator (1pt).
    static let dividerSoft = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F

    /// 일요일 일자 — 한국 캘린더 관습.
    static let sunday = Color(red: 0.863, green: 0.149, blue: 0.149) // #DC2626
}

extension Font {
    /// IBM Plex Mono fixed-size 헬퍼.
    static func papamooMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let psName: String = switch weight {
        case .bold, .heavy, .black: "IBMPlexMono-Bold"
        case .semibold: "IBMPlexMono-SemiBold"
        case .medium: "IBMPlexMono-Medium"
        default: "IBMPlexMono-Regular"
        }
        return .custom(psName, size: size)
    }

    /// Home main amount — mono 700, 64pt.
    static let papamooDisplay = Font.papamooMono(64, weight: .bold)

    /// Calendar month, large numbers — mono 700, 38pt.
    static let papamooTitle = Font.papamooMono(38, weight: .bold)

    /// List row amount — mono 700, 17pt.
    static let papamooAmount = Font.papamooMono(17, weight: .bold)

    /// Section labels (caps) — mono 700, 12pt.
    static let papamooMeta = Font.papamooMono(12, weight: .bold)

    /// Dates — mono 400, 12pt.
    static let papamooDate = Font.papamooMono(12, weight: .regular)
}
