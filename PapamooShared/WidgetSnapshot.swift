import Foundation

nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    let generatedAt: Date
    let subscriptions: [WidgetSubscriptionSnapshot]
    let monthlyTotal: Decimal
    let remainingThisMonth: Decimal
    let totalCount: Int
    let baseCurrency: String
}

nonisolated struct WidgetSubscriptionSnapshot: Codable, Equatable, Sendable {
    let name: String
    let category: String
    let amount: Decimal
    let currencyCode: String
    let nextPaymentDate: Date
    let daysUntil: Int
}

nonisolated struct WidgetSnapshotStore: Sendable {

    // MARK: - Properties

    static let fileName = "widget-snapshot.json"

    let fileURL: URL

    init(containerURL: URL) {
        self.fileURL = containerURL.appending(path: Self.fileName)
    }

    // MARK: - Methods

    func load() throws -> WidgetSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save(_ snapshot: WidgetSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }
}
