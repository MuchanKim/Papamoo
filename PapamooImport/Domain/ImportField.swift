import Foundation

enum ImportFieldSource: Equatable {
    case missing
    case ocr
    case presetMatch
    case user
    case defaultValue
}

struct ImportField<Value: Equatable>: Equatable {
    var value: Value?
    var source: ImportFieldSource
    var needsReview: Bool

    static var missing: Self {
        Self(value: nil, source: .missing, needsReview: false)
    }

    static func detected(_ value: Value, needsReview: Bool = false) -> Self {
        Self(value: value, source: .ocr, needsReview: needsReview)
    }

    static func preset(_ value: Value) -> Self {
        Self(value: value, source: .presetMatch, needsReview: false)
    }
}
