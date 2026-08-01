import Foundation
import SwiftData

@Observable
final class AddSubscriptionViewModel {
    private let subscriptionService: SubscriptionService
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

    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
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
        let draft = SubscriptionDraft(
            name: name,
            amount: amount,
            currencyCode: currencyCode,
            billingCycle: billingCycle,
            firstPaymentDate: firstPaymentDate,
            category: category,
            note: note,
            iconName: selectedPreset?.iconName,
            sourceImageData: nil,
            sourceCropRegion: nil
        )
        try subscriptionService.create(from: draft)
    }

    func update(_ subscription: Subscription) throws {
        try subscriptionService.saveChanges(to: subscription)
    }

    func delete(id: PersistentIdentifier) async throws {
        try await subscriptionService.delete(id: id)
    }
}
