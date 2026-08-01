import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct SubscriptionSynchronizationTests {
    @Test("다른 ModelContainer가 저장한 구독을 다시 조회한다")
    func refreshesAfterSeparateContainerSave() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appending(path: "subscriptions.store")
        let appContainer = try makeContainer(storeURL: storeURL)
        let extensionContainer = try makeContainer(storeURL: storeURL)
        let viewModel = HomeViewModel(context: appContainer.mainContext)

        viewModel.fetch()
        #expect(viewModel.subscriptions.isEmpty)

        let extensionContext = ModelContext(extensionContainer)
        extensionContext.insert(makeSubscription(name: "Shared subscription"))
        try extensionContext.save()

        viewModel.fetch()

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

        let viewModel = HomeViewModel(context: context)
        viewModel.fetch()
        #expect(viewModel.subscriptions.count == 2)

        let deletedID = deleted.persistentModelID
        deleted.note = "Unsaved edit before deletion"
        let store = SubscriptionDeletionStore(modelContainer: container)
        try await store.delete(id: deletedID)
        context.rollback()
        viewModel.removeSubscription(withID: deletedID)

        #expect(viewModel.subscriptions.map(\.name) == ["Remaining"])

        viewModel.fetch()
        #expect(viewModel.subscriptions.map(\.name) == ["Remaining"])
    }

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
}
