import SwiftUI

enum BillingCycle: String, Codable, CaseIterable, Sendable {
    case monthly
    case yearly

    var displayName: LocalizedStringResource {
        switch self {
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}
