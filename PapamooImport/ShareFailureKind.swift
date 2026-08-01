enum ShareFailureKind: Equatable {
    case insufficientData
    case rejected(PaymentDocumentType)
    case analysis
    case imageLoad
    case cropProcessing
}
