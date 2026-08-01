import CoreGraphics
import Foundation

nonisolated struct SubscriptionDraft: Sendable {
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
}
