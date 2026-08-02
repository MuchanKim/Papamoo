import Foundation
import SwiftData

/// 화면들이 같은 저장소와 서비스 인스턴스를 공유하도록 앱 전역 의존성을 한 번만 조립한다.
final class AppContainer {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let subscriptionStore: SubscriptionStore
    private let subscriptionService: SubscriptionService
    private let lifecycleSynchronizer: AppLifecycleSynchronizer

    init(modelContainer: ModelContainer, widgetSnapshotStore: WidgetSnapshotStore) {
        let modelContext = modelContainer.mainContext
        let subscriptionStore = SubscriptionStore(context: modelContext)
        let deletionStore = SubscriptionDeletionStore(modelContainer: modelContainer)
        let subscriptionService = SubscriptionService(
            context: modelContext,
            deletionStore: deletionStore
        )
        let pendingImportStore = PendingSubscriptionImportStore(modelContainer: modelContainer)
        let widgetSnapshotSynchronizer = WidgetSnapshotSynchronizer(
            context: modelContext,
            store: widgetSnapshotStore
        )

        self.modelContext = modelContext
        self.subscriptionStore = subscriptionStore
        self.subscriptionService = subscriptionService
        self.lifecycleSynchronizer = AppLifecycleSynchronizer(
            operations: .init(
                refreshSubscriptions: subscriptionStore.refresh,
                importPendingSubscriptions: {
                    _ = try await pendingImportStore.importPendingSubscriptions()
                },
                synchronizeNotifications: {
                    try NotificationManager.rescheduleAll(in: modelContext)
                },
                synchronizeWidgetSnapshot: {
                    try widgetSnapshotSynchronizer.synchronize()
                }
            )
        )
    }

    // MARK: - Methods

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

    func makeEditSubscriptionViewModel(
        subscription: Subscription
    ) -> AddSubscriptionViewModel {
        AddSubscriptionViewModel(
            subscriptionService: subscriptionService,
            editing: subscription
        )
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

    func makeAppLifecycleSynchronizer() -> AppLifecycleSynchronizer {
        lifecycleSynchronizer
    }
}

// MARK: - Extensions

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
