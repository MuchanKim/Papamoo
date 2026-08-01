import Foundation
import Observation
import OSLog
import UIKit

@MainActor
@Observable
final class ShareImportViewModel {
    private static let logger = Logger(
        subsystem: "com.moolab.Papamoo.ShareExtension",
        category: "PaymentImport"
    )

    private let extensionContext: NSExtensionContext
    private let ocrService = ShareOCRService()
    private let paymentAnalyzer: PaymentImportAnalyzer
    private var loadTask: Task<Void, Never>?
    private var cropTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var completionTask: Task<Void, Never>?
    private var imageData: Data?
    private var sourceDocumentData: Data?
    private var didLoadInput = false

    var phase: ShareImportPhase = .loading
    var previewImage: UIImage?
    var analysisPreviewImage: UIImage?
    var cropRegion: CGRect?
    var didAttemptCrop = false
    var draft = SubscriptionImportDraft()

    var name = ""
    var amountText = ""
    var currencyCode: String
    var billingCycle: BillingCycle = .monthly
    var firstPaymentDate: Date = .now
    var category: SubscriptionCategory = .other
    var note = ""
    var showsSourceImage = false
    var isSaving = false
    var isShowingSaveError = false
    private(set) var analysisSource: PaymentAnalysisSource?
    private(set) var lastAnalysisErrorDescription: String?

    let supportedCurrencies = ["KRW", "USD", "JPY"]

    var selectedPreviewImage: UIImage? {
        analysisPreviewImage ?? previewImage
    }

    init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
        self.currencyCode = UserDefaults(suiteName: AppGroup.identifier)?.string(forKey: "baseCurrency") ?? "KRW"
        let foundationModelService = ShareFoundationModelService()
        self.paymentAnalyzer = PaymentImportAnalyzer { lines in
            try await foundationModelService.extractPayment(from: lines)
        }
    }

    var isFormValid: Bool {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              let amount = Decimal(string: normalizedAmountText),
              amount > 0
        else {
            return false
        }
        return true
    }

    var normalizedAmountText: String {
        amountText.replacingOccurrences(of: ",", with: "")
    }

    func loadInputIfNeeded() async {
        guard didLoadInput == false else { return }
        didLoadInput = true
        phase = .loading

        do {
            let data = try await ShareImageLoader.loadData(from: extensionContext)
            let previewData = try await ShareImageProcessor.previewData(from: data)
            try Task.checkCancellation()
            guard let previewImage = UIImage(data: previewData) else {
                throw ShareImportError.imageDecodeFailed
            }
            self.previewImage = previewImage
            analysisPreviewImage = nil
            imageData = data
            sourceDocumentData = previewData
            phase = .review
        } catch is CancellationError {
            return
        } catch {
            let description = String(reflecting: error)
            Self.logger.error("Shared image loading failed: \(description, privacy: .public)")
            phase = .failed(.imageLoad)
        }
    }

    func retryImageLoad() {
        loadTask?.cancel()
        didLoadInput = false
        loadTask = Task { await loadInputIfNeeded() }
    }

    func beginCrop() {
        guard previewImage != nil else { return }
        phase = .crop
    }

    func applyCrop(_ region: CGRect) {
        guard let sourceDocumentData else {
            phase = .failed(.imageLoad)
            return
        }

        cropTask?.cancel()
        phase = .preparingCrop
        cropTask = Task {
            await Task.yield()
            do {
                let croppedData = try await ShareImageProcessor.croppedPreviewData(
                    from: sourceDocumentData,
                    normalizedRegion: region
                )
                try Task.checkCancellation()
                guard let croppedImage = UIImage(data: croppedData) else {
                    throw ShareImportError.imageDecodeFailed
                }

                cropRegion = region
                analysisPreviewImage = croppedImage
                didAttemptCrop = true
                phase = .review
            } catch is CancellationError {
                return
            } catch {
                let description = String(reflecting: error)
                Self.logger.error("Crop preview generation failed: \(description, privacy: .public)")
                phase = .failed(.cropProcessing)
            }
        }
    }

    func leaveCrop() {
        phase = .review
    }

    func startRecognition() {
        guard phase == .review else { return }
        guard let imageData else {
            phase = .failed(.imageLoad)
            return
        }

        analysisTask?.cancel()
        lastAnalysisErrorDescription = nil
        analysisSource = nil
        phase = .scanning
        analysisTask = Task {
            await Task.yield()
            do {
                let lines = try await ocrService.recognizeText(
                    in: imageData,
                    normalizedRegion: cropRegion
                )
                try Task.checkCancellation()
                switch try await paymentAnalyzer.analyze(ocrLines: lines) {
                case let .completed(result, source):
                    draft = result
                    analysisSource = source
                    applyDraftToForm()
                    phase = .form(result.hasRequiredValues && result.needsReview == false ? .complete : .partial)
                case let .rejected(documentType):
                    phase = .failed(.rejected(documentType))
                case .insufficient:
                    phase = .failed(.insufficientData)
                }
            } catch is CancellationError {
                return
            } catch {
                let description = String(reflecting: error)
                lastAnalysisErrorDescription = description
                Self.logger.error("Payment analysis failed: \(description, privacy: .public)")
                phase = .failed(.analysis)
            }
        }
    }

    func retryCropAfterFailure() {
        beginCrop()
    }

    func enterManualMode() {
        draft = SubscriptionImportDraft()
        name = ""
        amountText = ""
        currencyCode = UserDefaults(suiteName: AppGroup.identifier)?.string(forKey: "baseCurrency") ?? "KRW"
        billingCycle = .monthly
        firstPaymentDate = .now
        category = .other
        note = ""
        phase = .form(.manual)
    }

    func returnToReview() {
        isShowingSaveError = false
        phase = previewImage == nil ? .failed(.imageLoad) : .review
    }

    func save() {
        guard isFormValid, let amount = Decimal(string: normalizedAmountText), isSaving == false else {
            return
        }

        let record = ShareSubscriptionRecord(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            currencyCode: currencyCode,
            billingCycle: billingCycle,
            firstPaymentDate: firstPaymentDate,
            category: category,
            note: note,
            iconName: draft.iconName,
            sourceImageData: sourceDocumentData,
            sourceCropRegion: cropRegion
        )

        saveTask?.cancel()
        isSaving = true
        isShowingSaveError = false

        saveTask = Task {
            await Task.yield()
            do {
                let store = ShareSubscriptionStoreFactory.makeStore()
                try await store.save(record)
                try Task.checkCancellation()

                isSaving = false
                discardSessionData()
                phase = .saved
                completionTask = Task {
                    do {
                        try await Task.sleep(for: .milliseconds(650))
                        extensionContext.completeRequest(returningItems: nil)
                    } catch is CancellationError {
                        return
                    } catch {
                        let description = String(reflecting: error)
                        Self.logger.error("Share extension completion delay failed: \(description, privacy: .public)")
                    }
                }
            } catch is CancellationError {
                isSaving = false
            } catch {
                let description = String(reflecting: error)
                Self.logger.error("Subscription save failed: \(description, privacy: .public)")
                isShowingSaveError = true
                isSaving = false
            }
        }
    }

    func cancel() {
        loadTask?.cancel()
        cropTask?.cancel()
        analysisTask?.cancel()
        saveTask?.cancel()
        completionTask?.cancel()
        discardSessionData()
        extensionContext.cancelRequest(withError: ShareImportError.userCancelled)
    }

    private func applyDraftToForm() {
        name = draft.name.value ?? ""
        amountText = draft.amount.value.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        currencyCode = draft.currencyCode.value ?? currencyCode
        billingCycle = draft.billingCycle.value ?? .monthly
        firstPaymentDate = draft.firstPaymentDate.value ?? .now
        category = draft.category.value ?? .other
        note = ""
    }

    private func discardSessionData() {
        imageData = nil
        sourceDocumentData = nil
        previewImage = nil
        analysisPreviewImage = nil
        cropRegion = nil
        draft = SubscriptionImportDraft()
    }
}
