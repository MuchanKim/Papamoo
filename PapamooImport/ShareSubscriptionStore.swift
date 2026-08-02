import Foundation

nonisolated struct ShareSubscriptionStore: Sendable {

    // MARK: - Properties

    private let inbox = SubscriptionImportInbox()

    // MARK: - Methods

    @concurrent
    func save(_ record: ShareSubscriptionRecord) async throws {
        try inbox.enqueue(record.pendingImport)
    }
}
