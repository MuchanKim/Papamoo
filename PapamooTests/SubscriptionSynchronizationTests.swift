import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct SubscriptionSynchronizationTests {

    // MARK: - Methods

    @Test("다른 ModelContainer가 저장한 구독을 다시 조회한다")
    func refreshesAfterSeparateContainerSave() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appending(path: "subscriptions.store")
        let appContainer = try makeContainer(storeURL: storeURL)
        let extensionContainer = try makeContainer(storeURL: storeURL)
        let (viewModel, subscriptionStore) = makeHomeViewModel(container: appContainer)

        try subscriptionStore.refresh()
        #expect(viewModel.subscriptions.isEmpty)

        let extensionContext = ModelContext(extensionContainer)
        extensionContext.insert(makeSubscription(name: "Shared subscription"))
        try extensionContext.save()

        try subscriptionStore.refresh()

        #expect(viewModel.subscriptions.map(\.name) == ["Shared subscription"])
    }

    @Test("하나를 삭제해도 화면과 저장소의 나머지 구독을 유지한다")
    func deletingOneSubscriptionKeepsTheOthers() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let container = try makeContainer(
            storeURL: directory.appending(path: "subscriptions.store")
        )
        let context = container.mainContext
        let deleted = makeSubscription(name: "Deleted")
        let remaining = makeSubscription(name: "Remaining")
        context.insert(deleted)
        context.insert(remaining)
        try context.save()

        let (viewModel, subscriptionStore) = makeHomeViewModel(container: container)
        try subscriptionStore.refresh()
        #expect(viewModel.subscriptions.count == 2)

        let deletedID = deleted.persistentModelID
        deleted.note = "Unsaved edit before deletion"
        try await viewModel.deleteSubscription(withID: deletedID)
        try subscriptionStore.refresh()

        #expect(viewModel.subscriptions.map(\.name) == ["Remaining"])

        try subscriptionStore.refresh()
        #expect(viewModel.subscriptions.map(\.name) == ["Remaining"])
    }

    // MARK: - Private Methods

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "papamoo-sync-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeContainer(storeURL: URL) throws -> ModelContainer {
        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(
            "SubscriptionSynchronizationTests",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: Subscription.self, configurations: configuration)
    }

    private func makeSubscription(name: String) -> Subscription {
        Subscription(name: name, amount: 1, firstPaymentDate: .now)
    }

    private func makeHomeViewModel(
        container: ModelContainer
    ) -> (HomeViewModel, SubscriptionStore) {
        let subscriptionStore = SubscriptionStore(context: container.mainContext)
        let service = SubscriptionService(
            context: container.mainContext,
            deletionStore: SubscriptionDeletionStore(modelContainer: container),
            effects: .init(
                scheduleNotifications: { _ in },
                removeNotifications: { _ in },
                notifyStoreChanged: {}
            )
        )
        let viewModel = HomeViewModel(
            subscriptionStore: subscriptionStore,
            subscriptionService: service
        )
        return (viewModel, subscriptionStore)
    }
}
