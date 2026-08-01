import Foundation
import SwiftData

@Observable
final class AddSubscriptionViewModel {
    private let subscriptionService: SubscriptionService
    private let exchangeRate = ExchangeRateManager.shared

    var searchText = ""
    var selectedCategory: SubscriptionCategory?
    var selectedPreset: PresetService?
    private(set) var iconName: String?
    private var sourceImageData: Data?
    private var sourceCropRegion: CGRect?

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

    init(
        subscriptionService: SubscriptionService,
        editing subscription: Subscription
    ) {
        self.subscriptionService = subscriptionService
        self.iconName = subscription.iconName
        self.sourceImageData = subscription.sourceImageData
        self.sourceCropRegion = subscription.sourceCropRegion
        self.name = subscription.name
        self.amount = subscription.amount
        self.currencyCode = subscription.currencyCode
        self.billingCycle = subscription.billingCycle
        self.firstPaymentDate = subscription.firstPaymentDate
        self.category = subscription.category
        self.note = subscription.note
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
        iconName = preset.iconName
        name = preset.name
        category = preset.category
        // Preset prices are KRW-based; only auto-fill when base currency matches, otherwise let the user enter the local price.
        amount = currencyCode == "KRW" ? preset.defaultAmount : 0
    }

    func save() throws {
        try subscriptionService.create(from: draft)
    }

    func update(_ subscription: Subscription) throws {
        try subscriptionService.saveChanges(to: subscription, from: draft)
    }

    func delete(id: PersistentIdentifier) async throws {
        try await subscriptionService.delete(id: id)
    }

    private var draft: SubscriptionDraft {
        SubscriptionDraft(
            name: name,
            amount: amount,
            currencyCode: currencyCode,
            billingCycle: billingCycle,
            firstPaymentDate: firstPaymentDate,
            category: category,
            note: note,
            iconName: iconName,
            sourceImageData: sourceImageData,
            sourceCropRegion: sourceCropRegion
        )
    }
}
