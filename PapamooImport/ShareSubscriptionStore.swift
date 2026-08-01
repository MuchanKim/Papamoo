import Foundation

nonisolated struct ShareSubscriptionStore: Sendable {
    private let inbox = SubscriptionImportInbox()

    @concurrent
    func save(_ record: ShareSubscriptionRecord) async throws {
        try inbox.enqueue(record.pendingImport)
    }
}
