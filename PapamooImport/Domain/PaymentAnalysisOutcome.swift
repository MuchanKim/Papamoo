enum PaymentAnalysisOutcome: Equatable {
    case completed(SubscriptionImportDraft, source: PaymentAnalysisSource)
    case rejected(PaymentDocumentType)
    case insufficient
}

enum PaymentAnalysisSource: Equatable {
    case foundationModels
    case rulesFallback(PaymentInterpreterUnavailableReason)
}

enum PaymentInterpreterResult: Equatable, Sendable {
    case interpreted(PaymentEmailExtractionCandidate)
    case unavailable(PaymentInterpreterUnavailableReason)
}

enum PaymentInterpreterUnavailableReason: Equatable, Sendable {
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unsupportedLocale
    case unknown
}
