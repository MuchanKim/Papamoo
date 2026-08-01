struct PaymentEmailExtractionCandidate: Equatable, Sendable {
    var documentType: PaymentDocumentType
    var serviceName: String?
    var serviceEvidence: String?
    var amount: String?
    var currencyCode: String?
    var amountEvidence: String?
    var paymentDate: String?
    var paymentDateEvidence: String?
    var billingCycle: ExtractedBillingCycle?
    var billingCycleEvidence: String?
}

enum ExtractedBillingCycle: Equatable, Sendable {
    case monthly
    case yearly
}
