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

    /// Decimal을 fraction 0자리 정수 문자열로.
    static func amountString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(for: value) ?? "0"
    }
}
