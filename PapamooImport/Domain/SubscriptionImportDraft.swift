import Foundation

struct SubscriptionImportDraft: Equatable {

    var name: ImportField<String> = .missing
    var amount: ImportField<Decimal> = .missing
    var currencyCode: ImportField<String> = .missing
    var billingCycle: ImportField<BillingCycle> = .missing
    var firstPaymentDate: ImportField<Date> = .missing
    var category: ImportField<SubscriptionCategory> = .missing
    var iconName: String?

    var hasDetectedValue: Bool {
        name.value != nil ||
            amount.value != nil ||
            currencyCode.value != nil ||
            billingCycle.value != nil ||
            firstPaymentDate.value != nil ||
            category.value != nil
    }

    var hasRequiredValues: Bool {
        guard let name = name.value, name.isEmpty == false, let amount = amount.value else {
            return false
        }
        return amount > 0
    }

    var needsReviewFieldCount: Int {
        [
            name.needsReview,
            amount.needsReview,
            currencyCode.needsReview,
            billingCycle.needsReview,
            firstPaymentDate.needsReview,
            category.needsReview,
        ].filter { $0 }.count
    }

    var needsReview: Bool {
        needsReviewFieldCount > 0
    }

    var isPartial: Bool {
        hasDetectedValue && (hasRequiredValues == false || needsReview)
    }
}
