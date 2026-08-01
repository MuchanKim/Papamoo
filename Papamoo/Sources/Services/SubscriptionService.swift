import Foundation
import SwiftData

@MainActor
final class SubscriptionService {
    struct Effects {
        let scheduleNotifications: (Subscription) -> Void
        let removeNotifications: (PersistentIdentifier) -> Void
        let notifyStoreChanged: () -> Void

        static let live = Effects(
            scheduleNotifications: { subscription in
                NotificationManager.scheduleNotifications(for: subscription)
            },
            removeNotifications: { id in
                NotificationManager.removeNotifications(for: id)
            },
            notifyStoreChanged: {
                NotificationCenter.default.post(name: .subscriptionStoreDidChange, object: nil)
            }
        )
    }

    private let context: ModelContext
    private let deletionStore: SubscriptionDeletionStore
    private let effects: Effects

    init(
        context: ModelContext,
        deletionStore: SubscriptionDeletionStore,
        effects: Effects = .live
    ) {
        self.context = context
        self.deletionStore = deletionStore
        self.effects = effects
    }

    @discardableResult
    func create(from draft: SubscriptionDraft) throws -> Subscription {
        let subscription = Subscription(
            name: draft.name,
            amount: draft.amount,
            currencyCode: draft.currencyCode,
            billingCycle: draft.billingCycle,
            firstPaymentDate: draft.firstPaymentDate,
            category: draft.category,
            note: draft.note,
            iconName: draft.iconName,
            sourceImageData: draft.sourceImageData,
            sourceCropRegion: draft.sourceCropRegion
        )
        context.insert(subscription)

        do {
            try context.save()
        } catch {
            context.delete(subscription)
            throw error
        }

        effects.scheduleNotifications(subscription)
        effects.notifyStoreChanged()
        return subscription
    }

    func saveChanges(to subscription: Subscription) throws {
        try context.save()
        effects.removeNotifications(subscription.persistentModelID)
        effects.scheduleNotifications(subscription)
        effects.notifyStoreChanged()
    }

    func delete(id: PersistentIdentifier) async throws {
        try await deletionStore.delete(id: id)
        // mainContext의 미저장 변경이 별도 컨텍스트에서 완료된 삭제를 되살리지 않게 정리한다.
        context.rollback()
        effects.removeNotifications(id)
        effects.notifyStoreChanged()
    }
}
