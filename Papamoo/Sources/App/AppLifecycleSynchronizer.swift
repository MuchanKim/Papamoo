import Foundation

@MainActor
final class AppLifecycleSynchronizer {

    struct Operations {
        let refreshSubscriptions: () throws -> Void
        let importPendingSubscriptions: () async throws -> Void
        let synchronizeNotifications: () throws -> Void
        let synchronizeWidgetSnapshot: () throws -> Void
    }

    // MARK: - Properties

    private let operations: Operations

    init(operations: Operations) {
        self.operations = operations
    }

    // MARK: - Methods

    func synchronizeOnActivation() async throws {
        // 대기 중인 가져오기가 실패해도 기존 구독은 먼저 화면에 표시한다.
        try operations.refreshSubscriptions()
        try await operations.importPendingSubscriptions()
        try operations.refreshSubscriptions()
        try operations.synchronizeNotifications()
        try operations.synchronizeWidgetSnapshot()
    }

    func synchronizeAfterStoreChange() throws {
        try operations.refreshSubscriptions()
        try operations.synchronizeWidgetSnapshot()
    }

    func synchronizeWidgetSnapshot() throws {
        try operations.synchronizeWidgetSnapshot()
    }
}
