enum PaymentDocumentType: Equatable, Sendable {
    case completedPayment
    case refund
    case failedPayment
    case authorizationOnly
    case unknown
}
