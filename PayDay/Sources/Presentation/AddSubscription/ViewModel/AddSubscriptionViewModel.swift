import Foundation
import SwiftData

@Observable
final class AddSubscriptionViewModel {
    private let context: ModelContext

    var searchText = ""
    var selectedCategory: SubscriptionCategory?
    var selectedPreset: PresetService?

    var name = ""
    var amount: Decimal = 0
    var currencyCode = "KRW"
    var billingCycle: BillingCycle = .monthly
    var firstPaymentDate: Date = .now
    var category: SubscriptionCategory = .other
    var isRemindOneDayBefore = true
    var isRemindThreeDaysBefore = false
    var note = ""

    init(context: ModelContext) {
        self.context = context
    }

    var filteredServices: [PresetService] {
        PresetService.all.filter { service in
            let matchesSearch = searchText.isEmpty || service.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || service.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var isFormValid: Bool {
        !name.isEmpty && amount > 0
    }

    func selectPreset(_ preset: PresetService) {
        selectedPreset = preset
        name = preset.name
        amount = preset.defaultAmount
        category = preset.category
    }

    func save() -> Bool {
        let subscription = Subscription(
            name: name,
            amount: amount,
            currencyCode: currencyCode,
            billingCycle: billingCycle,
            firstPaymentDate: firstPaymentDate,
            category: category,
            note: note,
            iconName: selectedPreset?.iconName,
            isRemindOneDayBefore: isRemindOneDayBefore,
            isRemindThreeDaysBefore: isRemindThreeDaysBefore
        )
        context.insert(subscription)
        do {
            try context.save()
            NotificationManager.scheduleNotifications(for: subscription)
            return true
        } catch {
            return false
        }
    }

    func update(_ subscription: Subscription) {
        NotificationManager.removeNotifications(for: subscription)
        NotificationManager.scheduleNotifications(for: subscription)
        try? context.save()
    }

    func delete(_ subscription: Subscription) {
        NotificationManager.removeNotifications(for: subscription)
        context.delete(subscription)
        try? context.save()
    }
}
