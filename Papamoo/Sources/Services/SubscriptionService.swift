import CoreGraphics
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

    func saveChanges(
        to subscription: Subscription,
        from draft: SubscriptionDraft
    ) throws {
        apply(draft, to: subscription)

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

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

    private func apply(_ draft: SubscriptionDraft, to subscription: Subscription) {
        subscription.name = draft.name
        subscription.amount = draft.amount
        subscription.currencyCode = draft.currencyCode
        subscription.billingCycle = draft.billingCycle
        subscription.firstPaymentDate = draft.firstPaymentDate
        subscription.category = draft.category
        subscription.note = draft.note
        subscription.iconName = draft.iconName
        subscription.sourceImageData = draft.sourceImageData
        subscription.sourceCropX = draft.sourceCropRegion.map { Double($0.minX) }
        subscription.sourceCropY = draft.sourceCropRegion.map { Double($0.minY) }
        subscription.sourceCropWidth = draft.sourceCropRegion.map { Double($0.width) }
        subscription.sourceCropHeight = draft.sourceCropRegion.map { Double($0.height) }
    }
}
