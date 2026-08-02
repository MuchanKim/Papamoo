import SwiftUI

enum PapamooColor {
    static let background = Color(red: 0.039, green: 0.039, blue: 0.039)

    static let surface = Color(red: 0.078, green: 0.078, blue: 0.078)

    static let text = Color.white

    static let textMuted = Color(red: 0.322, green: 0.322, blue: 0.322)

    static let textSubtle = Color(red: 0.451, green: 0.451, blue: 0.451)

    static let accent = Color(red: 0.980, green: 0.800, blue: 0.082)

    static let ruler = accent

    static let dividerSoft = Color(red: 0.122, green: 0.122, blue: 0.122)

    static let sunday = Color(red: 0.863, green: 0.149, blue: 0.149)
}

// MARK: - Extensions

extension Font {

    static func papamooMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let psName: String = switch weight {
        case .bold, .heavy, .black: "IBMPlexMono-Bold"
        case .semibold: "IBMPlexMono-SemiBold"
        case .medium: "IBMPlexMono-Medium"
        default: "IBMPlexMono-Regular"
        }
        return .custom(psName, size: size)
    }

    static let papamooDisplay = Font.papamooMono(64, weight: .bold)

    static let papamooTitle = Font.papamooMono(38, weight: .bold)

    static let papamooAmount = Font.papamooMono(17, weight: .bold)

    static let papamooMeta = Font.papamooMono(12, weight: .bold)

    static let papamooDate = Font.papamooMono(12, weight: .regular)
}
