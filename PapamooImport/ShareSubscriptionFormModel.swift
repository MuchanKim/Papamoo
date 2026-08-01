import Foundation
import Observation

@MainActor
@Observable
final class ShareSubscriptionFormModel {
    let supportedCurrencies = ["KRW", "USD", "JPY"]

    var name = ""
    var amountText = ""
    var currencyCode: String
    var billingCycle: BillingCycle = .monthly
    var firstPaymentDate: Date = .now
    var category: SubscriptionCategory = .other
    var note = ""

    init(baseCurrency: String) {
        self.currencyCode = baseCurrency
    }

    var amount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: ""))
    }

    var isValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
            amount.map { $0 > 0 } == true
    }

    func apply(_ draft: SubscriptionImportDraft) {
        name = draft.name.value ?? ""
        amountText = draft.amount.value.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        currencyCode = draft.currencyCode.value ?? currencyCode
        billingCycle = draft.billingCycle.value ?? .monthly
        firstPaymentDate = draft.firstPaymentDate.value ?? .now
        category = draft.category.value ?? .other
        note = ""
    }

    func reset(baseCurrency: String) {
        name = ""
        amountText = ""
        currencyCode = baseCurrency
        billingCycle = .monthly
        firstPaymentDate = .now
        category = .other
        note = ""
    }
}
