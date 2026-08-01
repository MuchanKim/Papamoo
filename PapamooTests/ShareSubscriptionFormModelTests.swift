import Foundation
import Testing
@testable import Papamoo

@MainActor
struct ShareSubscriptionFormModelTests {
    @Test("서비스명과 양수가 입력되면 폼이 유효하다")
    func validatesRequiredFields() {
        let form = ShareSubscriptionFormModel(baseCurrency: "KRW")

        form.name = "  Netflix  "
        form.amountText = "17,900"

        #expect(form.isValid)
        #expect(form.amount == 17_900)
    }

    @Test("서비스명이 비어 있거나 금액이 양수가 아니면 폼이 유효하지 않다")
    func rejectsInvalidRequiredFields() {
        let form = ShareSubscriptionFormModel(baseCurrency: "KRW")
        form.name = "   "
        form.amountText = "1000"

        #expect(form.isValid == false)

        form.name = "Netflix"
        form.amountText = "0"

        #expect(form.isValid == false)
    }

    @Test("분석 초안을 폼에 반영하고 기존 통화는 누락 시 유지한다")
    func appliesAnalysisDraft() throws {
        let form = ShareSubscriptionFormModel(baseCurrency: "JPY")
        let amount = try #require(Decimal(string: "10.50"))
        var draft = SubscriptionImportDraft()
        draft.name = .detected("GitHub")
        draft.amount = .detected(amount)
        draft.billingCycle = .detected(.yearly)
        draft.category = .preset(.productivity)

        form.apply(draft)

        #expect(form.name == "GitHub")
        #expect(form.amountText == "10.5")
        #expect(form.currencyCode == "JPY")
        #expect(form.billingCycle == .yearly)
        #expect(form.category == .productivity)
    }

    @Test("수동 입력으로 전환하면 기준 통화와 기본값으로 초기화한다")
    func resetsForManualEntry() {
        let form = ShareSubscriptionFormModel(baseCurrency: "USD")
        form.name = "Existing"
        form.amountText = "12"
        form.note = "Memo"

        form.reset(baseCurrency: "KRW")

        #expect(form.name.isEmpty)
        #expect(form.amountText.isEmpty)
        #expect(form.currencyCode == "KRW")
        #expect(form.billingCycle == .monthly)
        #expect(form.category == .other)
        #expect(form.note.isEmpty)
    }
}
