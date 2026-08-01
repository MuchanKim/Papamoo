import Foundation
import SwiftData

/// ViewModel 생성 책임을 갖는 컴포지션 루트.
/// AppCoordinator(navigation 책임)와 분리되어, 각자 단일 책임 원칙을 만족한다.
final class ViewModelFactory {
    private let modelContext: ModelContext
    private let deletionStore: SubscriptionDeletionStore
    private let pendingImportStore: PendingSubscriptionImportStore
    private let widgetSnapshotSynchronizer: WidgetSnapshotSynchronizer

    init(modelContainer: ModelContainer, widgetSnapshotStore: WidgetSnapshotStore) {
        self.modelContext = modelContainer.mainContext
        self.deletionStore = SubscriptionDeletionStore(modelContainer: modelContainer)
        self.pendingImportStore = PendingSubscriptionImportStore(modelContainer: modelContainer)
        self.widgetSnapshotSynchronizer = WidgetSnapshotSynchronizer(
            context: modelContainer.mainContext,
            store: widgetSnapshotStore
        )
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(context: modelContext, deletionStore: deletionStore)
    }

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(context: modelContext)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(modelContext: modelContext)
    }

    func makeAddSubscriptionViewModel() -> AddSubscriptionViewModel {
        AddSubscriptionViewModel(context: modelContext, deletionStore: deletionStore)
    }

    func makeImageImportViewModel(
        imageData: Data,
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> ShareImportViewModel {
        ShareImportViewModel(
            imageData: imageData,
            saveRecord: { record in
                try self.saveImportedSubscription(record)
            },
            onComplete: onComplete,
            onCancel: onCancel
        )
    }

    func importPendingSubscriptions() async throws {
        _ = try await pendingImportStore.importPendingSubscriptions()
    }

    func synchronizeWidgetSnapshot() throws {
        try widgetSnapshotSynchronizer.synchronize()
    }

    private func saveImportedSubscription(_ record: ShareSubscriptionRecord) throws {
        let subscription = Subscription(
            name: record.name,
            amount: record.amount,
            currencyCode: record.currencyCode,
            billingCycle: record.billingCycle,
            firstPaymentDate: record.firstPaymentDate,
            category: record.category,
            note: record.note,
            iconName: record.iconName,
            sourceImageData: record.sourceImageData,
            sourceCropRegion: record.sourceCropRegion
        )
        modelContext.insert(subscription)

        do {
            try modelContext.save()
            NotificationManager.scheduleNotifications(for: subscription)
            NotificationCenter.default.post(name: .subscriptionStoreDidChange, object: nil)
        } catch {
            modelContext.delete(subscription)
            throw error
        }
    }
}
