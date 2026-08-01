import Foundation
import SwiftData

@Observable
final class AddSubscriptionViewModel {
    private let context: ModelContext
    private let deletionStore: SubscriptionDeletionStore
    private let exchangeRate = ExchangeRateManager.shared

    var searchText = ""
    var selectedCategory: SubscriptionCategory?
    var selectedPreset: PresetService?

    var baseCurrency: String { exchangeRate.baseCurrency }
    var supportedCurrencies: [String] { exchangeRate.supportedCurrencies }

    func currencyLabel(for code: String) -> String {
        "\(code) (\(exchangeRate.currencySymbol(for: code)))"
    }

    /// Preset prices are stored in KRW; convert to the user's base currency for display.
    func presetDisplayAmount(_ preset: PresetService) -> Decimal {
        exchangeRate.convertToBase(amount: preset.defaultAmount, from: "KRW")
    }

    var name = ""
    var amount: Decimal = 0
    var currencyCode: String = ExchangeRateManager.shared.baseCurrency
    var billingCycle: BillingCycle = .monthly
    var firstPaymentDate: Date = .now
    var category: SubscriptionCategory = .other
    var note = ""

    init(context: ModelContext, deletionStore: SubscriptionDeletionStore) {
        self.context = context
        self.deletionStore = deletionStore
    }

    var filteredServices: [PresetService] {
        PresetService.all.filter { service in
            let matchesSearch = searchText.isEmpty || service.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || service.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var isFormValid: Bool {
        Subscription.isValid(name: name, amount: amount)
    }

    func selectPreset(_ preset: PresetService) {
        selectedPreset = preset
        name = preset.name
        category = preset.category
        // Preset prices are KRW-based; only auto-fill when base currency matches, otherwise let the user enter the local price.
        amount = currencyCode == "KRW" ? preset.defaultAmount : 0
    }

    func save() throws {
        let subscription = Subscription(
            name: name,
            amount: amount,
            currencyCode: currencyCode,
            billingCycle: billingCycle,
            firstPaymentDate: firstPaymentDate,
            category: category,
            note: note,
            iconName: selectedPreset?.iconName
        )
        context.insert(subscription)
        do {
            try context.save()
            NotificationManager.scheduleNotifications(for: subscription)
            NotificationCenter.default.post(name: .subscriptionStoreDidChange, object: nil)
        } catch {
            context.delete(subscription)
            throw error
        }
    }

    func update(_ subscription: Subscription) throws {
        try context.save()
        NotificationManager.removeNotifications(for: subscription)
        NotificationManager.scheduleNotifications(for: subscription)
        NotificationCenter.default.post(name: .subscriptionStoreDidChange, object: nil)
    }

    func delete(id: PersistentIdentifier) async throws {
        try await deletionStore.delete(id: id)
        // 편집 화면이 mainContext에 남긴 미저장 변경이 외부 컨텍스트의 삭제를 되살리지 않게 정리한다.
        context.rollback()
        NotificationManager.removeNotifications(for: id)
        NotificationCenter.default.post(name: .subscriptionStoreDidChange, object: nil)
    }
}
