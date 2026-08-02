import Foundation
import Observation
import OSLog
import UIKit

@MainActor
@Observable
final class ShareImportViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.moolab.Papamoo.ShareExtension",
        category: "PaymentImport"
    )

    private let inputLoader: () async throws -> Data
    private let recordSaver: (ShareSubscriptionRecord) async throws -> Void
    private let completionAction: () -> Void
    private let cancellationAction: () -> Void
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

    let form: ShareSubscriptionFormModel
    var phase: ShareImportPhase = .loading
    var previewImage: UIImage?
    var analysisPreviewImage: UIImage?
    var cropRegion: CGRect?
    var didAttemptCrop = false
    private(set) var draft = SubscriptionImportDraft()
    var showsSourceImage = false
    var isSaving = false
    private(set) var isSaved = false
    var isShowingSaveError = false
    private(set) var analysisSource: PaymentAnalysisSource?
    private(set) var lastAnalysisErrorDescription: String?

    var selectedPreviewImage: UIImage? {
        analysisPreviewImage ?? previewImage
    }

    var preventsInteractiveDismissal: Bool {
        if isSaving || isSaved { return true }

        switch phase {
        case .loading, .preparingCrop, .scanning:
            return true
        case .review, .crop, .form, .failed:
            return false
        }
    }

    private init(
        inputLoader: @escaping () async throws -> Data,
        recordSaver: @escaping (ShareSubscriptionRecord) async throws -> Void,
        completionAction: @escaping () -> Void,
        cancellationAction: @escaping () -> Void
    ) {
        self.inputLoader = inputLoader
        self.recordSaver = recordSaver
        self.completionAction = completionAction
        self.cancellationAction = cancellationAction
        self.form = ShareSubscriptionFormModel(baseCurrency: Self.baseCurrency)
        let foundationModelService = ShareFoundationModelService()
        self.paymentAnalyzer = PaymentImportAnalyzer { lines in
            try await foundationModelService.extractPayment(from: lines)
        }
    }

    convenience init(extensionContext: NSExtensionContext) {
        self.init(
            inputLoader: {
                try await ShareImageLoader.loadData(from: extensionContext)
            },
            recordSaver: { record in
                let store = ShareSubscriptionStoreFactory.makeStore()
                try await store.save(record)
            },
            completionAction: {
                extensionContext.completeRequest(returningItems: nil)
            },
            cancellationAction: {
                extensionContext.cancelRequest(withError: ShareImportError.userCancelled)
            }
        )
    }

    convenience init(
        imageData: Data,
        saveRecord: @escaping (ShareSubscriptionRecord) async throws -> Void,
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.init(
            inputLoader: { imageData },
            recordSaver: saveRecord,
            completionAction: onComplete,
            cancellationAction: onCancel
        )
    }

    // MARK: - Methods

    func loadInputIfNeeded() async {
        guard didLoadInput == false else { return }
        didLoadInput = true
        phase = .loading

        do {
            let data = try await inputLoader()
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
        form.reset(baseCurrency: Self.baseCurrency)
        phase = .form(.manual)
    }

    func returnToReview() {
        isShowingSaveError = false
        phase = previewImage == nil ? .failed(.imageLoad) : .review
    }

    func save() {
        guard form.isValid,
              let amount = form.amount,
              isSaving == false,
              isSaved == false
        else {
            return
        }

        let record = ShareSubscriptionRecord(
            name: form.name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            currencyCode: form.currencyCode,
            billingCycle: form.billingCycle,
            firstPaymentDate: form.firstPaymentDate,
            category: form.category,
            note: form.note,
            iconName: draft.iconName,
            sourceImageData: sourceDocumentData,
            sourceCropRegion: cropRegion
        )

        saveTask?.cancel()
        isSaving = true
        isSaved = false
        isShowingSaveError = false

        saveTask = Task {
            await Task.yield()
            do {
                try await recordSaver(record)
                try Task.checkCancellation()

                isSaving = false
                isSaved = true
                completionTask = Task {
                    do {
                        try await Task.sleep(for: .milliseconds(700))
                        discardSessionData()
                        completionAction()
                    } catch is CancellationError {
                        return
                    } catch {
                        let description = String(reflecting: error)
                        Self.logger.error("Import completion delay failed: \(description, privacy: .public)")
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
        stopWork()
        cancellationAction()
    }

    func stopWork() {
        loadTask?.cancel()
        cropTask?.cancel()
        analysisTask?.cancel()
        saveTask?.cancel()
        completionTask?.cancel()
        loadTask = nil
        cropTask = nil
        analysisTask = nil
        saveTask = nil
        completionTask = nil
        isSaving = false
        isSaved = false
        discardSessionData()
    }

    // MARK: - Private Methods

    private func applyDraftToForm() {
        form.apply(draft)
    }

    private func discardSessionData() {
        imageData = nil
        sourceDocumentData = nil
        previewImage = nil
        analysisPreviewImage = nil
        cropRegion = nil
        draft = SubscriptionImportDraft()
    }

    private static var baseCurrency: String {
        UserDefaults(suiteName: AppGroup.identifier)?.string(forKey: "baseCurrency") ?? "KRW"
    }
}
