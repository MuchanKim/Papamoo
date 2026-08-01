import Foundation

nonisolated enum AppGroup {
    static let identifier = "group.com.moolab.Papamoo"
}

/// 앱 전역 통화 포맷 헬퍼.
enum CurrencyFormatter {
    /// 통화 코드의 narrow symbol.
    static func symbol(for code: String) -> String {
        switch code {
        case "KRW": "₩"
        case "USD": "$"
        case "JPY": "¥"
        default: code
        }
    }

    static func maximumFractionDigits(for currencyCode: String) -> Int {
        switch currencyCode {
        case "KRW", "JPY": 0
        default: 2
        }
    }

    static func amountString(_ value: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maximumFractionDigits(for: currencyCode)
        guard let result = formatter.string(from: NSDecimalNumber(decimal: value)) else {
            preconditionFailure("Unable to format amount for currency \(currencyCode)")
        }
        return result
    }
}
