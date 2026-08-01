import Foundation
import Testing
@testable import Papamoo

@MainActor
struct SubscriptionImportParserTests {
    private let parser = SubscriptionImportParser()

    @Test("Netflix 결제 화면에서 필수 필드를 추출한다")
    func parsesNetflixPayment() throws {
        let draft = parser.parse(lines: [
            "NETFLIX",
            "결제 완료",
            "결제 일시 2026.08.15 14:32:18",
            "결제 금액 17,000원",
            "월간 자동 결제",
        ])

        #expect(draft.name.value == "Netflix")
        #expect(draft.amount.value == Decimal(17_000))
        #expect(draft.currencyCode.value == "KRW")
        #expect(draft.billingCycle.value == .monthly)
        #expect(draft.category.value == .streaming)
        #expect(draft.hasRequiredValues)

        let date = try #require(draft.firstPaymentDate.value)
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2026)
        #expect(components.month == 8)
        #expect(components.day == 15)
    }

    @Test("일부 값만 찾으면 부분 결과로 분류한다")
    func returnsPartialResult() {
        let draft = parser.parse(lines: ["결제 완료", "결제 금액 9,900원"])

        #expect(draft.amount.value == Decimal(9_900))
        #expect(draft.name.value == nil)
        #expect(draft.isPartial)
    }

    @Test("사용 가능한 값이 없으면 실패 결과를 만든다")
    func returnsEmptyResult() {
        let draft = parser.parse(lines: ["감사합니다", "다음에 또 만나요"])

        #expect(draft.hasDetectedValue == false)
        #expect(draft.hasRequiredValues == false)
    }

    @Test("금액 후보가 모호하면 임의로 고르지 않는다")
    func leavesAmbiguousAmountEmpty() {
        let draft = parser.parse(lines: [
            "NETFLIX",
            "결제 완료",
            "상품 금액 17,000원",
            "할인 금액 5,000원",
        ])

        #expect(draft.name.value == "Netflix")
        #expect(draft.amount.value == nil)
        #expect(draft.isPartial)
    }

    @Test("명시된 연간 주기를 인식한다")
    func parsesYearlyBillingCycle() {
        let draft = parser.parse(lines: ["Adobe", "Payment confirmed", "Annual plan", "Total USD 59.99"])

        #expect(draft.billingCycle.value == .yearly)
        #expect(draft.amount.value == Decimal(string: "59.99"))
        #expect(draft.currencyCode.value == "USD")
    }

    @Test("GitHub 구매 영수증에서 결제 정보를 추출한다")
    func parsesGitHubPurchaseReceipt() throws {
        let draft = parser.parse(lines: [
            "Thanks for your GitHub.com purchase!",
            "GITHUB RECEIPT - PERSONAL PURCHASE -",
            "- month: $0.13 USD",
            "Tax: $0.00 USD",
            "Total: $0.13 USD*",
            "Charged to: MasterCard (5*** **** **** 4394)",
            "Transaction ID: ch_3TzHxJFr6CCHwli1zkQLsop",
            "Date: 31 Jul 2026 08:02AM PDT",
        ])

        #expect(draft.name.value == "GitHub")
        #expect(draft.amount.value == Decimal(string: "0.13"))
        #expect(draft.currencyCode.value == "USD")
        #expect(draft.billingCycle.value == .monthly)

        let date = try #require(draft.firstPaymentDate.value)
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2026)
        #expect(components.month == 7)
        #expect(components.day == 31)
    }

    @Test("향후 카드 청구 안내는 완료 결제로 처리하지 않는다")
    func rejectsUpcomingCardCharge() {
        let draft = parser.parse(lines: [
            "Your subscription will be charged to your card tomorrow",
            "Total: $17.99 USD",
        ])

        #expect(draft.hasDetectedValue == false)
    }

    @Test("갱신 예정 메일은 결제 완료로 처리하지 않는다")
    func rejectsRenewalReminder() {
        let draft = parser.parse(lines: [
            "Netflix",
            "Your plan renews tomorrow",
            "Total USD 17.99",
        ])

        #expect(draft.hasDetectedValue == false)
    }

    @Test("완료 근거가 없는 금액 안내는 결제로 처리하지 않는다")
    func rejectsDocumentWithoutCompletedEvidence() {
        let draft = parser.parse(lines: ["Netflix", "Total USD 17.99"])

        #expect(draft.hasDetectedValue == false)
    }

    @Test("환불 완료 메일은 fallback 파서에서도 결제로 처리하지 않는다")
    func rejectsRefundEmail() {
        let draft = parser.parse(lines: [
            "Netflix refund completed",
            "Refund amount $17.99",
        ])

        #expect(draft.hasDetectedValue == false)
    }

    @Test("결제 실패 메일은 fallback 파서에서도 결제로 처리하지 않는다")
    func rejectsFailedPaymentEmail() {
        let draft = parser.parse(lines: [
            "Netflix",
            "Payment failed",
            "Amount $17.99",
        ])

        #expect(draft.hasDetectedValue == false)
    }
}
