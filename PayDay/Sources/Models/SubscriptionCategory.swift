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

    var iconTintColor: Color {
        switch self {
        case .streaming: Color(red: 142/255, green: 142/255, blue: 147/255)
        case .ai: Color(red: 99/255, green: 99/255, blue: 102/255)
        case .productivity: Color(red: 174/255, green: 174/255, blue: 178/255)
        case .other: Color(red: 199/255, green: 199/255, blue: 204/255)
        }
    }
}
