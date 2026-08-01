import Foundation
import SwiftData

/// ViewModel 생성 책임을 갖는 컴포지션 루트.
/// AppCoordinator(navigation 책임)와 분리되어, 각자 단일 책임 원칙을 만족한다.
final class ViewModelFactory {
    private let modelContext: ModelContext
    private let subscriptionStore: SubscriptionStore
    private let subscriptionService: SubscriptionService
    private let pendingImportStore: PendingSubscriptionImportStore
    private let widgetSnapshotSynchronizer: WidgetSnapshotSynchronizer

    init(modelContainer: ModelContainer, widgetSnapshotStore: WidgetSnapshotStore) {
        self.modelContext = modelContainer.mainContext
        self.subscriptionStore = SubscriptionStore(context: modelContainer.mainContext)
        let deletionStore = SubscriptionDeletionStore(modelContainer: modelContainer)
        self.subscriptionService = SubscriptionService(
            context: modelContainer.mainContext,
            deletionStore: deletionStore
        )
        self.pendingImportStore = PendingSubscriptionImportStore(modelContainer: modelContainer)
        self.widgetSnapshotSynchronizer = WidgetSnapshotSynchronizer(
            context: modelContainer.mainContext,
            store: widgetSnapshotStore
        )
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            subscriptionStore: subscriptionStore,
            subscriptionService: subscriptionService
        )
    }

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(subscriptionStore: subscriptionStore)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(modelContext: modelContext)
    }

    func makeAddSubscriptionViewModel() -> AddSubscriptionViewModel {
        AddSubscriptionViewModel(subscriptionService: subscriptionService)
    }

    func makeImageImportViewModel(
        imageData: Data,
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> ShareImportViewModel {
        ShareImportViewModel(
            imageData: imageData,
            saveRecord: { record in
                try self.subscriptionService.create(from: SubscriptionDraft(record: record))
            },
            onComplete: onComplete,
            onCancel: onCancel
        )
    }

    func importPendingSubscriptions() async throws {
        _ = try await pendingImportStore.importPendingSubscriptions()
    }

    func refreshSubscriptions() throws {
        try subscriptionStore.refresh()
    }

    func synchronizeWidgetSnapshot() throws {
        try widgetSnapshotSynchronizer.synchronize()
    }

    func synchronizeNotifications() throws {
        try NotificationManager.rescheduleAll(in: modelContext)
    }
}

private extension SubscriptionDraft {
    init(record: ShareSubscriptionRecord) {
        self.init(
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
    }
}
