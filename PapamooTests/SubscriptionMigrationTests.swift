import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct SubscriptionMigrationTests {
    @Test("V1 저장소를 원본 문서 필드가 있는 V2로 마이그레이션한다")
    func migratesV1StoreToV2WithoutLosingSubscriptionData() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "default.store")

        try writeV1Store(to: storeURL)

        let schema = Schema(versionedSchema: PapamooSchemaV2.self)
        let configuration = ModelConfiguration(
            "Papamoo",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: PapamooMigrationPlan.self,
            configurations: [configuration]
        )
        let subscriptions = try container.mainContext.fetch(FetchDescriptor<Subscription>())
        let subscription = try #require(subscriptions.first)

        #expect(subscriptions.count == 1)
        #expect(subscription.name == "GitHub")
        #expect(subscription.amount == Decimal(string: "0.13"))
        #expect(subscription.currencyCode == "USD")
        #expect(subscription.sourceImageData == nil)
        #expect(subscription.sourceCropRegion == nil)
    }

    private func writeV1Store(to storeURL: URL) throws {
        let schema = Schema(versionedSchema: PapamooSchemaV1.self)
        let configuration = ModelConfiguration(
            "Papamoo",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        context.insert(
            PapamooSchemaV1.Subscription(
                name: "GitHub",
                amount: Decimal(13) / 100,
                currencyCode: "USD",
                billingCycle: .monthly,
                firstPaymentDate: .now,
                category: .productivity,
                note: "Receipt",
                iconName: "GitHub"
            )
        )
        try context.save()
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "papamoo-migration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
