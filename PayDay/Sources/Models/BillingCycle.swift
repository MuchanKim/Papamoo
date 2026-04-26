import SwiftUI

enum BillingCycle: String, Codable, CaseIterable {
    case monthly
    case yearly

    var displayName: LocalizedStringResource {
        switch self {
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    var monthMultiplier: Int {
        switch self {
        case .monthly: 1
        case .yearly: 12
        }
    }
}
