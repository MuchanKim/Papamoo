import Foundation
import SwiftData

/// ViewModel 생성 책임을 갖는 컴포지션 루트.
/// AppCoordinator(navigation 책임)와 분리되어, 각자 단일 책임 원칙을 만족한다.
final class ViewModelFactory {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(context: modelContext)
    }

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(context: modelContext)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(modelContext: modelContext)
    }

    func makeAddSubscriptionViewModel() -> AddSubscriptionViewModel {
        AddSubscriptionViewModel(context: modelContext)
    }
}
