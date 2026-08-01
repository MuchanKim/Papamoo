import Foundation
import SwiftData

@ModelActor
actor SubscriptionDeletionStore {
    enum DeletionError: LocalizedError {
        case subscriptionNotFound

        var errorDescription: String? {
            "삭제할 구독을 찾지 못했습니다."
        }
    }

    func delete(id: PersistentIdentifier) throws {
        guard let subscription = modelContext.model(for: id) as? Subscription else {
            throw DeletionError.subscriptionNotFound
        }

        modelContext.delete(subscription)
        try modelContext.save()
    }
}
