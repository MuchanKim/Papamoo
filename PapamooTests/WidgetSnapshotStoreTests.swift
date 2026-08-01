import Foundation
import Testing
@testable import Papamoo

struct WidgetSnapshotStoreTests {
    @Test("위젯 스냅샷을 원자 파일에 저장하고 다시 읽는다")
    func savesAndLoadsSnapshot() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WidgetSnapshotStore(containerURL: directory)
        let snapshot = makeSnapshot()

        try store.save(snapshot)

        #expect(try store.load() == snapshot)
    }

    @Test("스냅샷 파일이 없으면 데이터 없음으로 구분한다")
    func returnsNilWhenSnapshotDoesNotExist() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try WidgetSnapshotStore(containerURL: directory).load() == nil)
    }

    @Test("손상된 스냅샷을 빈 데이터로 바꾸지 않고 오류로 전달한다")
    func throwsWhenSnapshotIsCorrupted() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = WidgetSnapshotStore(containerURL: directory)
        try Data("not-json".utf8).write(to: store.fileURL)

        #expect(throws: DecodingError.self) {
            try store.load()
        }
    }

    private func makeSnapshot() -> WidgetSnapshot {
        WidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            subscriptions: [
                WidgetSubscriptionSnapshot(
                    name: "GitHub",
                    category: "productivity",
                    amount: Decimal(13) / 100,
                    currencyCode: "USD",
                    nextPaymentDate: Date(timeIntervalSince1970: 1_700_086_400),
                    daysUntil: 1
                ),
            ],
            monthlyTotal: Decimal(13) / 100,
            remainingThisMonth: Decimal(13) / 100,
            totalCount: 1,
            baseCurrency: "USD"
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "papamoo-widget-snapshot-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
