import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct PendingSubscriptionImportStoreTests {
    @Test("공유 익스텐션의 대기 항목을 앱 저장소로 가져온다")
    func importsQueuedSubscription() async throws {
        let testDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        let inbox = SubscriptionImportInbox(
            directoryURL: testDirectory.appending(path: "inbox", directoryHint: .isDirectory)
        )
        let amount = try #require(Decimal(string: "0.13"))
        try inbox.enqueue(
            PendingSubscriptionImport(
                name: "GitHub",
                amount: amount,
                currencyCode: "USD",
                billingCycle: .monthly,
                firstPaymentDate: .now,
                category: .productivity,
                note: "",
                iconName: "GitHub",
                sourceImageData: Data("receipt".utf8),
                sourceCropRegion: nil
            )
        )

        let container = try makeContainer(
            storeURL: testDirectory.appending(path: "subscriptions.store")
        )
        let store = PendingSubscriptionImportStore(modelContainer: container, inbox: inbox)

        let importedCount = try await store.importPendingSubscriptions()

        #expect(importedCount == 1)
        let subscriptions = try container.mainContext.fetch(FetchDescriptor<Subscription>())
        let subscription = try #require(subscriptions.first)
        #expect(subscription.name == "GitHub")
        #expect(subscription.amount == amount)
        #expect(subscription.currencyCode == "USD")
        #expect(subscription.category == .productivity)
        #expect(subscription.iconName == "GitHub")
        #expect(try inbox.entries().isEmpty)
    }

    @Test("손상된 대기 항목은 삭제하거나 빈 구독으로 대체하지 않는다")
    func preservesMalformedQueuedImport() async throws {
        let testDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: testDirectory) }

        let inboxDirectory = testDirectory.appending(path: "inbox", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: inboxDirectory, withIntermediateDirectories: true)
        let malformedFile = inboxDirectory.appending(path: "malformed.import")
        try Data("not a property list".utf8).write(to: malformedFile)

        let inbox = SubscriptionImportInbox(directoryURL: inboxDirectory)
        let container = try makeContainer(
            storeURL: testDirectory.appending(path: "subscriptions.store")
        )
        let store = PendingSubscriptionImportStore(modelContainer: container, inbox: inbox)

        do {
            _ = try await store.importPendingSubscriptions()
            Issue.record("손상된 가져오기 파일은 오류를 반환해야 합니다.")
        } catch {
            #expect(FileManager.default.fileExists(atPath: malformedFile.path))
        }

        #expect(try container.mainContext.fetch(FetchDescriptor<Subscription>()).isEmpty)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "papamoo-pending-import-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeContainer(storeURL: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "PendingSubscriptionImportStoreTests",
            schema: Schema([Subscription.self]),
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: Subscription.self, configurations: configuration)
    }
}
