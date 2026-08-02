import Foundation

@MainActor
struct PaymentImportAnalyzer {
    typealias Interpreter = ([String]) async throws -> PaymentInterpreterResult

    // MARK: - Properties

    private let interpreter: Interpreter
    private let parser: SubscriptionImportParser
    private let mapper: PaymentEmailExtractionMapper

    init(
        parser: SubscriptionImportParser = SubscriptionImportParser(),
        mapper: PaymentEmailExtractionMapper = PaymentEmailExtractionMapper(),
        interpreter: @escaping Interpreter
    ) {
        self.parser = parser
        self.mapper = mapper
        self.interpreter = interpreter
    }

    // MARK: - Methods

    func analyze(ocrLines: [String]) async throws -> PaymentAnalysisOutcome {
        let normalizedLines = ocrLines.filter {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
        guard normalizedLines.isEmpty == false else {
            return .insufficient
        }

        switch try await interpreter(normalizedLines) {
        case let .interpreted(candidate):
            return switch mapper.map(candidate, ocrLines: normalizedLines) {
            case let .completed(draft):
                .completed(draft, source: .foundationModels)
            case let .rejected(documentType):
                .rejected(documentType)
            case .insufficient:
                .insufficient
            }

        case let .unavailable(reason):
            let draft = parser.parse(lines: normalizedLines)
            return draft.hasDetectedValue
                ? .completed(draft, source: .rulesFallback(reason))
                : .insufficient
        }
    }
}
