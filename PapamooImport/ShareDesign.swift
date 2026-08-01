import SwiftUI

enum ShareColor {
    static let background = PapamooColor.background
    static let surface = PapamooColor.surface
    static let secondarySurface = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let accent = PapamooColor.accent
    static let divider = PapamooColor.dividerSoft
}

extension Font {
    static var shareMeta: Font {
        .papamooMeta
    }

    static var shareAmount: Font {
        .papamooAmount
    }
}
