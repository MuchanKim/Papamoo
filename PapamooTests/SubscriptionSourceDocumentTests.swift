import CoreGraphics
import Foundation
import SwiftData
import Testing
@testable import Papamoo

@MainActor
struct SubscriptionSourceDocumentTests {
    @Test("원본 문서와 선택 영역을 구독에 저장한다")
    func persistsSourceDocument() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "papamoo-source-document-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let schema = Schema([Subscription.self])
        let configuration = ModelConfiguration(
            "SourceDocumentTests",
            schema: schema,
            url: directory.appending(path: "subscriptions.store"),
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Subscription.self, configurations: configuration)
        let context = ModelContext(container)
        let imageData = Data("source-document".utf8)
        let cropRegion = CGRect(x: 0.1, y: 0.2, width: 0.7, height: 0.6)
        let amount = try #require(Decimal(string: "0.13"))
        let subscription = Subscription(
            name: "GitHub",
            amount: amount,
            currencyCode: "USD",
            firstPaymentDate: .now,
            sourceImageData: imageData,
            sourceCropRegion: cropRegion
        )

        context.insert(subscription)
        try context.save()

        let readContext = ModelContext(container)
        let stored = try #require(try readContext.fetch(FetchDescriptor<Subscription>()).first)
        #expect(stored.sourceImageData == imageData)
        #expect(stored.sourceCropRegion == cropRegion)
    }

    @Test("직접 추가한 구독은 원본 문서가 없어도 저장할 수 있다")
    func allowsMissingSourceDocument() {
        let subscription = Subscription(
            name: "Manual",
            amount: 1,
            firstPaymentDate: .now
        )

        #expect(subscription.sourceImageData == nil)
        #expect(subscription.sourceCropRegion == nil)
    }
}
