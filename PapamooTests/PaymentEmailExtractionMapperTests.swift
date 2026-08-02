import Foundation
import Testing
@testable import Papamoo

@MainActor
struct PaymentEmailExtractionMapperTests {

    // MARK: - Properties

    private let mapper = PaymentEmailExtractionMapper()

    // MARK: - Methods

    @Test("결제 완료 이메일을 구독 초안으로 구조화한다")
    func mapsCompletedPaymentEmail() throws {
        let extraction = candidate(
            amountEvidence: "Total charged: USD 17.99",
            paymentDate: "2026-07-31",
            paymentDateEvidence: "Payment date: July 31, 2026",
            billingCycle: .monthly,
            billingCycleEvidence: "Monthly membership"
        )

        let result = mapper.map(
            extraction,
            ocrLines: [
                "Your Netflix payment is confirmed",
                "Total charged: USD 17.99",
                "Payment date: July 31, 2026",
                "Monthly membership",
            ]
        )

        let draft = try #require(completedDraft(from: result))
        #expect(draft.name.value == "Netflix")
        #expect(draft.amount.value == Decimal(string: "17.99"))
        #expect(draft.currencyCode.value == "USD")
        #expect(draft.currencyCode.needsReview == false)
        #expect(draft.billingCycle.value == .monthly)
        #expect(draft.category.value == .streaming)
        #expect(draft.hasRequiredValues)
    }

    @Test("환불 이메일은 결제 초안으로 만들지 않는다")
    func rejectsRefundEmail() {
        var extraction = candidate(amountEvidence: "Refund amount: USD 17.99")
        extraction.documentType = .refund

        let result = mapper.map(
            extraction,
            ocrLines: ["Your Netflix payment is confirmed", "Refund amount: USD 17.99"]
        )

        #expect(result == .rejected(.refund))
    }

    @Test("OCR 원문에 없는 모델 값은 사용하지 않는다")
    func rejectsUnsupportedModelValues() {
        let extraction = PaymentEmailExtractionCandidate(
            documentType: .completedPayment,
            serviceName: "Invented Service",
            serviceEvidence: "Invented Service",
            amount: "99.99",
            currencyCode: "USD",
            amountEvidence: "Total charged: USD 99.99",
            paymentDate: nil,
            paymentDateEvidence: nil,
            billingCycle: nil,
            billingCycleEvidence: nil
        )

        let result = mapper.map(
            extraction,
            ocrLines: ["A real service", "Total charged: USD 9.99"]
        )

        #expect(result == .insufficient)
    }

    @Test("모델 날짜와 evidence 날짜가 다르면 날짜를 사용하지 않는다")
    func rejectsMismatchedPaymentDate() throws {
        let extraction = candidate(
            amountEvidence: "Total charged: USD 17.99",
            paymentDate: "2026-08-31",
            paymentDateEvidence: "Payment date: July 31, 2026"
        )

        let result = mapper.map(
            extraction,
            ocrLines: [
                "Your Netflix payment is confirmed",
                "Total charged: USD 17.99",
                "Payment date: July 31, 2026",
            ]
        )

        let draft = try #require(completedDraft(from: result))
        #expect(draft.firstPaymentDate.value == nil)
    }

    @Test("모델 결제 주기와 evidence가 다르면 주기를 사용하지 않는다")
    func rejectsMismatchedBillingCycle() throws {
        let extraction = candidate(
            amountEvidence: "Total charged: USD 17.99",
            billingCycle: .yearly,
            billingCycleEvidence: "Monthly membership"
        )

        let result = mapper.map(
            extraction,
            ocrLines: [
                "Your Netflix payment is confirmed",
                "Total charged: USD 17.99",
                "Monthly membership",
            ]
        )

        let draft = try #require(completedDraft(from: result))
        #expect(draft.billingCycle.value == nil)
    }

    @Test("달러 기호만 있으면 USD 통화를 검토 대상으로 표시한다")
    func marksAmbiguousDollarCurrencyForReview() throws {
        let extraction = candidate(amountEvidence: "Total charged: $17.99")

        let result = mapper.map(
            extraction,
            ocrLines: ["Your Netflix payment is confirmed", "Total charged: $17.99"]
        )

        let draft = try #require(completedDraft(from: result))
        #expect(draft.currencyCode.value == "USD")
        #expect(draft.currencyCode.needsReview)
        #expect(draft.needsReview)
    }

    @Test("GitHub 구매 영수증의 Foundation Models 응답을 매핑한다")
    func mapsGitHubPurchaseReceipt() throws {
        let extraction = PaymentEmailExtractionCandidate(
            documentType: .completedPayment,
            serviceName: "GitHub.com",
            serviceEvidence: "Thanks for your GitHub.com purchase!",
            amount: "0.13",
            currencyCode: "USD",
            amountEvidence: "Total: $0.13 USD*",
            paymentDate: "2026-07-31",
            paymentDateEvidence: "Date: 31 Jul 2026 08:02AM PDT",
            billingCycle: .monthly,
            billingCycleEvidence: "- month: $0.13 USD"
        )

        let result = mapper.map(
            extraction,
            ocrLines: [
                "Thanks for your GitHub.com purchase!",
                "- month: $0.13 USD",
                "Total: $0.13 USD*",
                "Date: 31 Jul 2026 08:02AM PDT",
            ]
        )

        let draft = try #require(completedDraft(from: result))
        #expect(draft.name.value == "GitHub")
        #expect(draft.amount.value == Decimal(string: "0.13"))
        #expect(draft.currencyCode.value == "USD")
        #expect(draft.billingCycle.value == .monthly)
        #expect(draft.firstPaymentDate.value != nil)
    }

    // MARK: - Private Methods

    private func candidate(
        amountEvidence: String,
        paymentDate: String? = nil,
        paymentDateEvidence: String? = nil,
        billingCycle: ExtractedBillingCycle? = nil,
        billingCycleEvidence: String? = nil
    ) -> PaymentEmailExtractionCandidate {
        PaymentEmailExtractionCandidate(
            documentType: .completedPayment,
            serviceName: "Netflix",
            serviceEvidence: "Your Netflix payment is confirmed",
            amount: "17.99",
            currencyCode: "USD",
            amountEvidence: amountEvidence,
            paymentDate: paymentDate,
            paymentDateEvidence: paymentDateEvidence,
            billingCycle: billingCycle,
            billingCycleEvidence: billingCycleEvidence
        )
    }

    private func completedDraft(from result: PaymentEmailMappingResult) -> SubscriptionImportDraft? {
        guard case let .completed(draft) = result else { return nil }
        return draft
    }
}
