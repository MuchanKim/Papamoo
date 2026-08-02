import FoundationModels

@Generable(description: "결제 이메일의 처리 상태")
enum FoundationModelPaymentDocumentType {
    case completedPayment
    case refund
    case failedPayment
    case authorizationOnly
    case unknown

    var paymentDocumentType: PaymentDocumentType {
        switch self {
        case .completedPayment: .completedPayment
        case .refund: .refund
        case .failedPayment: .failedPayment
        case .authorizationOnly: .authorizationOnly
        case .unknown: .unknown
        }
    }
}

@Generable(description: "이메일에 명시된 구독 결제 주기")
enum FoundationModelBillingCycle {
    case monthly
    case yearly

    var extractedBillingCycle: ExtractedBillingCycle {
        switch self {
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }
}

@Generable(description: "결제 이메일 OCR 텍스트에서 추출한 정보")
struct FoundationModelPaymentEmailResponse {

    @Guide(description: "completedPayment, refund, failedPayment, authorizationOnly, unknown 중 하나")
    var documentType: FoundationModelPaymentDocumentType

    @Guide(description: "결제된 구독 서비스 이름. 명시되지 않았으면 nil")
    var serviceName: String?

    @Guide(description: "서비스 이름의 근거가 되는 OCR 원문 한 줄. 없으면 nil")
    var serviceEvidence: String?

    @Guide(description: "최종 청구 금액의 숫자만 반환. 천 단위 구분자와 통화 기호는 제외하고 없으면 nil")
    var amount: String?

    @Guide(description: "KRW, USD, JPY 중 명시된 통화 코드. 확정할 수 없으면 nil")
    var currencyCode: String?

    @Guide(description: "최종 청구 금액과 통화의 근거가 되는 OCR 원문 한 줄. 없으면 nil")
    var amountEvidence: String?

    @Guide(description: "실제 결제일을 yyyy-MM-dd 형식으로 반환. 명시되지 않았으면 nil")
    var paymentDate: String?

    @Guide(description: "결제일의 근거가 되는 OCR 원문 한 줄. 없으면 nil")
    var paymentDateEvidence: String?

    @Guide(description: "결제 주기가 명시된 경우 monthly 또는 yearly. 없으면 nil")
    var billingCycle: FoundationModelBillingCycle?

    @Guide(description: "결제 주기의 근거가 되는 OCR 원문 한 줄. 없으면 nil")
    var billingCycleEvidence: String?

    var candidate: PaymentEmailExtractionCandidate {
        PaymentEmailExtractionCandidate(
            documentType: documentType.paymentDocumentType,
            serviceName: serviceName,
            serviceEvidence: serviceEvidence,
            amount: amount,
            currencyCode: currencyCode,
            amountEvidence: amountEvidence,
            paymentDate: paymentDate,
            paymentDateEvidence: paymentDateEvidence,
            billingCycle: billingCycle?.extractedBillingCycle,
            billingCycleEvidence: billingCycleEvidence
        )
    }
}
