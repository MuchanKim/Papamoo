import Foundation
import Testing
@testable import Papamoo

@MainActor
struct PaymentImportAnalyzerTests {
    @Test("FM이 성공하면 누락 필드를 규칙 파서로 채우지 않는다")
    func doesNotMergeRulesWhenFoundationModelsSucceeds() async throws {
        let candidate = PaymentEmailExtractionCandidate(
            documentType: .completedPayment,
            serviceName: "Netflix",
            serviceEvidence: "Netflix payment confirmed",
            amount: nil,
            currencyCode: nil,
            amountEvidence: nil,
            paymentDate: nil,
            paymentDateEvidence: nil,
            billingCycle: nil,
            billingCycleEvidence: nil
        )
        let analyzer = PaymentImportAnalyzer { _ in .interpreted(candidate) }

        let outcome = try await analyzer.analyze(ocrLines: [
            "Netflix payment confirmed",
            "Total USD 17.99",
        ])

        let draft = try #require(completedDraft(from: outcome))
        #expect(draft.name.value == "Netflix")
        #expect(draft.amount.value == nil)
    }

    @Test("FM을 사용할 수 없을 때만 규칙 파서를 사용한다")
    func usesRulesOnlyWhenFoundationModelsIsUnavailable() async throws {
        let analyzer = PaymentImportAnalyzer { _ in
            .unavailable(.deviceNotEligible)
        }

        let outcome = try await analyzer.analyze(ocrLines: [
            "Netflix",
            "Payment confirmed",
            "Total USD 17.99",
        ])

        guard case let .completed(draft, source) = outcome else {
            Issue.record("규칙 fallback의 완료 결과가 필요합니다.")
            return
        }
        #expect(draft.amount.value == Decimal(string: "17.99"))
        #expect(source == .rulesFallback(.deviceNotEligible))
    }

    @Test("FM 오류는 규칙 파서로 덮지 않고 그대로 전달한다")
    func propagatesFoundationModelsError() async {
        let analyzer = PaymentImportAnalyzer { _ in
            throw StubError.modelFailed
        }

        await #expect(throws: StubError.modelFailed) {
            try await analyzer.analyze(ocrLines: [
                "Netflix",
                "Payment confirmed",
                "Total USD 17.99",
            ])
        }
    }

    @Test("FM의 환불 판정은 규칙 파서로 재시도하지 않는다")
    func doesNotFallbackForRefund() async throws {
        let candidate = PaymentEmailExtractionCandidate(
            documentType: .refund,
            serviceName: "Netflix",
            serviceEvidence: "Netflix refund completed",
            amount: "17.99",
            currencyCode: "USD",
            amountEvidence: "Refund amount USD 17.99",
            paymentDate: nil,
            paymentDateEvidence: nil,
            billingCycle: nil,
            billingCycleEvidence: nil
        )
        let analyzer = PaymentImportAnalyzer { _ in .interpreted(candidate) }

        let outcome = try await analyzer.analyze(ocrLines: [
            "Netflix refund completed",
            "Payment confirmed",
            "Total USD 17.99",
        ])

        #expect(outcome == .rejected(.refund))
    }

    private func completedDraft(from outcome: PaymentAnalysisOutcome) -> SubscriptionImportDraft? {
        guard case let .completed(draft, _) = outcome else { return nil }
        return draft
    }
}

private enum StubError: Error, Equatable {
    case modelFailed
}
