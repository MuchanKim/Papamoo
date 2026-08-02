import Foundation
import SwiftData

@MainActor
@Observable
final class SubscriptionStore {

    // MARK: - Properties

    private let context: ModelContext
    private(set) var subscriptions: [Subscription] = []

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Methods

    /// 별도 ModelContainer를 사용하는 공유 확장의 변경까지 앱 복귀 시 다시 읽는다.
    func refresh() throws {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\Subscription.firstPaymentDate)]
        )
        subscriptions = try context.fetch(descriptor)
    }
}
