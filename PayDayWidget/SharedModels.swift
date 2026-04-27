import Foundation
import SwiftData
import SwiftUI

// Duplicated from main app for widget target access
enum BillingCycle: String, Codable, CaseIterable {
    case monthly
    case yearly
}

enum SubscriptionCategory: String, Codable, CaseIterable {
    case streaming
    case ai
    case productivity
    case other

    var iconSystemName: String {
        switch self {
        case .streaming: "play.fill"
        case .ai: "sparkle"
        case .productivity: "doc.text.fill"
        case .other: "clock"
        }
    }
}

@Model
final class Subscription {
    var name: String
    var amount: Decimal
    var currencyCode: String
    var billingCycle: BillingCycle
    var firstPaymentDate: Date
    var category: SubscriptionCategory
    var note: String
    var iconName: String?

    init(name: String, amount: Decimal, currencyCode: String = "KRW", billingCycle: BillingCycle = .monthly, firstPaymentDate: Date, category: SubscriptionCategory = .other, note: String = "", iconName: String? = nil) {
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.firstPaymentDate = firstPaymentDate
        self.category = category
        self.note = note
        self.iconName = iconName
    }

    var nextPaymentDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.startOfDay(for: firstPaymentDate)
        guard start <= today else { return start }
        let component: Calendar.Component = billingCycle == .monthly ? .month : .year
        var candidate = start
        while candidate <= today {
            guard let next = calendar.date(byAdding: component, value: 1, to: candidate) else { return candidate }
            candidate = next
        }
        return candidate
    }

    var daysUntilNextPayment: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let next = calendar.startOfDay(for: nextPaymentDate)
        return calendar.dateComponents([.day], from: today, to: next).day ?? 0
    }

    var monthlyAmount: Decimal {
        switch billingCycle {
        case .monthly: amount
        case .yearly: amount / 12
        }
    }
}
