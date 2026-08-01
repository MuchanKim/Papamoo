import CoreGraphics
import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct AddSubscriptionViewModelTests {
    @Test("편집 중인 값은 저장하기 전까지 원본 구독을 변경하지 않는다")
    func editingKeepsSubscriptionUnchangedUntilSave() throws {
        let store = try makeStore()
        defer { try? FileManager.default.removeItem(at: store.directoryURL) }
        let subscription = Subscription(
            name: "Before",
            amount: 1,
            currencyCode: "KRW",
            firstPaymentDate: .now,
            note: "Original",
            sourceImageData: Data("receipt".utf8),
            sourceCropRegion: CGRect(x: 0.1, y: 0.2, width: 0.7, height: 0.6)
        )
        store.container.mainContext.insert(subscription)
        try store.container.mainContext.save()
        let service = makeService(container: store.container)
        let viewModel = AddSubscriptionViewModel(
            subscriptionService: service,
            editing: subscription
        )

        viewModel.name = "After"
        viewModel.note = "Changed"

        #expect(subscription.name == "Before")
        #expect(subscription.note == "Original")

        try viewModel.update(subscription)

        #expect(subscription.name == "After")
        #expect(subscription.note == "Changed")
        #expect(subscription.sourceImageData == Data("receipt".utf8))
        #expect(subscription.sourceCropRegion == CGRect(x: 0.1, y: 0.2, width: 0.7, height: 0.6))
    }

    private func makeStore() throws -> AddSubscriptionTestStore {
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "papamoo-add-subscription-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(
            "AddSubscriptionViewModelTests",
            schema: schema,
            url: directoryURL.appending(path: "subscriptions.store"),
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: Subscription.self,
            configurations: configuration
        )
        return AddSubscriptionTestStore(
            container: container,
            directoryURL: directoryURL
        )
    }

    private func makeService(container: ModelContainer) -> SubscriptionService {
        SubscriptionService(
            context: container.mainContext,
            deletionStore: SubscriptionDeletionStore(modelContainer: container),
            effects: .init(
                scheduleNotifications: { _ in },
                removeNotifications: { _ in },
                notifyStoreChanged: {}
            )
        )
    }
}

private struct AddSubscriptionTestStore {
    let container: ModelContainer
    let directoryURL: URL
}
