import Foundation
import Testing
@testable import Papamoo

@MainActor
struct CurrencyFormatterTests {
    @Test("USD 소수 금액을 0으로 반올림하지 않는다")
    func preservesUSDFraction() throws {
        let amount = try #require(Decimal(string: "0.13"))

        let formatted = CurrencyFormatter.amountString(amount, currencyCode: "USD")

        #expect(formatted.contains("13"))
        #expect(CurrencyFormatter.maximumFractionDigits(for: "USD") == 2)
    }

    @Test("소수 단위를 사용하지 않는 통화는 정수 정밀도를 사용한다")
    func usesIntegerPrecisionForKRWAndJPY() {
        #expect(CurrencyFormatter.maximumFractionDigits(for: "KRW") == 0)
        #expect(CurrencyFormatter.maximumFractionDigits(for: "JPY") == 0)
    }
}
