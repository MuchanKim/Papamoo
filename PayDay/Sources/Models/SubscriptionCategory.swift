import SwiftUI

enum SubscriptionCategory: String, Codable, CaseIterable {
    case streaming
    case ai
    case productivity
    case other

    var displayName: LocalizedStringResource {
        switch self {
        case .streaming: "Streaming"
        case .ai: "AI"
        case .productivity: "Productivity"
        case .other: "Other"
        }
    }

    var iconSystemName: String {
        switch self {
        case .streaming: "play.fill"
        case .ai: "sparkle"
        case .productivity: "doc.text.fill"
        case .other: "clock"
        }
    }
}
