import CoreGraphics
import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct SubscriptionMigrationTests {

    // MARK: - Methods

    @Test("V1 저장소를 현재 스키마로 마이그레이션한다")
    func migratesV1StoreToCurrentSchemaWithoutLosingSubscriptionData() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "default.store")

        try writeV1Store(to: storeURL)

        let schema = Schema(versionedSchema: PapamooSchemaV3.self)
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
        #expect(subscription.sourceImportID == nil)
    }

    @Test("V2 저장소를 가져오기 ID가 있는 V3로 마이그레이션한다")
    func migratesV2StoreToV3WithoutLosingSourceDocumentData() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "default.store")

        try writeV2Store(to: storeURL)

        let schema = Schema(versionedSchema: PapamooSchemaV3.self)
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
        #expect(subscription.sourceImageData == Data("receipt".utf8))
        #expect(subscription.sourceCropRegion == CGRect(x: 0.1, y: 0.2, width: 0.7, height: 0.6))
        #expect(subscription.sourceImportID == nil)
    }

    // MARK: - Private Methods

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

    private func writeV2Store(to storeURL: URL) throws {
        let schema = Schema(versionedSchema: PapamooSchemaV2.self)
        let configuration = ModelConfiguration(
            "Papamoo",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        context.insert(
            PapamooSchemaV2.Subscription(
                name: "GitHub",
                amount: Decimal(13) / 100,
                currencyCode: "USD",
                billingCycle: .monthly,
                firstPaymentDate: .now,
                category: .productivity,
                note: "Receipt",
                iconName: "GitHub",
                sourceImageData: Data("receipt".utf8),
                sourceCropRegion: CGRect(x: 0.1, y: 0.2, width: 0.7, height: 0.6)
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
