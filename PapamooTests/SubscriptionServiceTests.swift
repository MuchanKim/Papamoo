import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct SubscriptionServiceTests {
    @Test("구독 생성 후 저장과 후속 작업을 실행한다")
    func createsSubscriptionAndRunsEffects() throws {
        let store = try makeStore()
        defer { try? FileManager.default.removeItem(at: store.directoryURL) }
        let container = store.container
        var scheduledIDs: [PersistentIdentifier] = []
        var storeChangeCount = 0
        let service = makeService(
            container: container,
            scheduleNotifications: { scheduledIDs.append($0.persistentModelID) },
            notifyStoreChanged: { storeChangeCount += 1 }
        )

        let created = try service.create(from: makeDraft(name: "Created"))
        let stored = try container.mainContext.fetch(FetchDescriptor<Subscription>())

        #expect(stored.map(\.name) == ["Created"])
        #expect(scheduledIDs == [created.persistentModelID])
        #expect(storeChangeCount == 1)
    }

    @Test("구독 수정 후 알림을 교체하고 변경을 알린다")
    func savesChangesAndRunsEffects() throws {
        let store = try makeStore()
        defer { try? FileManager.default.removeItem(at: store.directoryURL) }
        let container = store.container
        var scheduledIDs: [PersistentIdentifier] = []
        var removedIDs: [PersistentIdentifier] = []
        var storeChangeCount = 0
        let service = makeService(
            container: container,
            scheduleNotifications: { scheduledIDs.append($0.persistentModelID) },
            removeNotifications: { removedIDs.append($0) },
            notifyStoreChanged: { storeChangeCount += 1 }
        )
        let subscription = Subscription(name: "Before", amount: 1, firstPaymentDate: .now)
        container.mainContext.insert(subscription)
        try container.mainContext.save()

        subscription.name = "After"
        try service.saveChanges(to: subscription)

        let stored = try #require(container.mainContext.fetch(FetchDescriptor<Subscription>()).first)
        #expect(stored.name == "After")
        #expect(removedIDs == [subscription.persistentModelID])
        #expect(scheduledIDs == [subscription.persistentModelID])
        #expect(storeChangeCount == 1)
    }

    @Test("구독 삭제 후 저장소와 후속 작업을 정리한다")
    func deletesSubscriptionAndRunsEffects() async throws {
        let store = try makeStore()
        defer { try? FileManager.default.removeItem(at: store.directoryURL) }
        let container = store.container
        var removedIDs: [PersistentIdentifier] = []
        var storeChangeCount = 0
        let service = makeService(
            container: container,
            removeNotifications: { removedIDs.append($0) },
            notifyStoreChanged: { storeChangeCount += 1 }
        )
        let subscription = Subscription(name: "Deleted", amount: 1, firstPaymentDate: .now)
        container.mainContext.insert(subscription)
        try container.mainContext.save()
        let id = subscription.persistentModelID

        try await service.delete(id: id)

        #expect(try container.mainContext.fetch(FetchDescriptor<Subscription>()).isEmpty)
        #expect(removedIDs == [id])
        #expect(storeChangeCount == 1)
    }

    private func makeStore() throws -> TestStore {
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "papamoo-subscription-service-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(
            "SubscriptionServiceTests",
            schema: schema,
            url: directoryURL.appending(path: "subscriptions.store"),
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: Subscription.self,
            configurations: configuration
        )
        return TestStore(container: container, directoryURL: directoryURL)
    }

    private func makeService(
        container: ModelContainer,
        scheduleNotifications: @escaping (Subscription) -> Void = { _ in },
        removeNotifications: @escaping (PersistentIdentifier) -> Void = { _ in },
        notifyStoreChanged: @escaping () -> Void = {}
    ) -> SubscriptionService {
        SubscriptionService(
            context: container.mainContext,
            deletionStore: SubscriptionDeletionStore(modelContainer: container),
            effects: .init(
                scheduleNotifications: scheduleNotifications,
                removeNotifications: removeNotifications,
                notifyStoreChanged: notifyStoreChanged
            )
        )
    }

    private func makeDraft(name: String) -> SubscriptionDraft {
        SubscriptionDraft(
            name: name,
            amount: 1,
            currencyCode: "KRW",
            billingCycle: .monthly,
            firstPaymentDate: .now,
            category: .other,
            note: "",
            iconName: nil,
            sourceImageData: nil,
            sourceCropRegion: nil
        )
    }
}

private struct TestStore {
    let container: ModelContainer
    let directoryURL: URL
}
