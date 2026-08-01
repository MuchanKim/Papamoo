import Foundation

nonisolated struct ShareSubscriptionRecord: Sendable {
    let name: String
    let amount: Decimal
    let currencyCode: String
    let billingCycle: BillingCycle
    let firstPaymentDate: Date
    let category: SubscriptionCategory
    let note: String
    let iconName: String?
    let sourceImageData: Data?
    let sourceCropRegion: CGRect?

    var pendingImport: PendingSubscriptionImport {
        PendingSubscriptionImport(
            name: name,
            amount: amount,
            currencyCode: currencyCode,
            billingCycle: billingCycle,
            firstPaymentDate: firstPaymentDate,
            category: category,
            note: note,
            iconName: iconName,
            sourceImageData: sourceImageData,
            sourceCropRegion: sourceCropRegion
        )
    }
}
