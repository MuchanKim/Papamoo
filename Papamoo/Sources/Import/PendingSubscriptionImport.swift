import CoreGraphics
import Foundation

nonisolated struct PendingSubscriptionImport: Codable, Sendable {
    let id: UUID
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

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        currencyCode: String,
        billingCycle: BillingCycle,
        firstPaymentDate: Date,
        category: SubscriptionCategory,
        note: String,
        iconName: String?,
        sourceImageData: Data?,
        sourceCropRegion: CGRect?
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.firstPaymentDate = firstPaymentDate
        self.category = category
        self.note = note
        self.iconName = iconName
        self.sourceImageData = sourceImageData
        self.sourceCropRegion = sourceCropRegion
    }
}
