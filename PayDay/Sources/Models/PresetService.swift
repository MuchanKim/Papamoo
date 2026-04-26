import Foundation

struct PresetService: Identifiable, Hashable {
    let id: UUID

    static func == (lhs: PresetService, rhs: PresetService) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let name: String
    let category: SubscriptionCategory
    let defaultAmount: Decimal
    let iconName: String?

    init(name: String, category: SubscriptionCategory, defaultAmount: Decimal, iconName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.defaultAmount = defaultAmount
        self.iconName = iconName ?? name
    }

    static let all: [PresetService] = [
        // Streaming
        PresetService(name: "Netflix", category: .streaming, defaultAmount: 17000),
        PresetService(name: "YouTube Premium", category: .streaming, defaultAmount: 14900),
        PresetService(name: "Apple Music", category: .streaming, defaultAmount: 10900),
        PresetService(name: "Spotify", category: .streaming, defaultAmount: 10900),
        PresetService(name: "Disney+", category: .streaming, defaultAmount: 9900),
        PresetService(name: "Apple TV+", category: .streaming, defaultAmount: 9900),
        PresetService(name: "Watcha", category: .streaming, defaultAmount: 7900),
        // AI
        PresetService(name: "Claude", category: .ai, defaultAmount: 28000),
        PresetService(name: "ChatGPT", category: .ai, defaultAmount: 28000),
        PresetService(name: "Gemini", category: .ai, defaultAmount: 28000),
        PresetService(name: "Grok", category: .ai, defaultAmount: 28000),
        PresetService(name: "Perplexity", category: .ai, defaultAmount: 28000),
        PresetService(name: "Copilot", category: .ai, defaultAmount: 28000),
        PresetService(name: "Midjourney", category: .ai, defaultAmount: 13000, iconName: nil),
        PresetService(name: "Cursor", category: .ai, defaultAmount: 28000, iconName: nil),
        // Productivity
        PresetService(name: "Notion", category: .productivity, defaultAmount: 12000),
        PresetService(name: "Figma", category: .productivity, defaultAmount: 20000),
        PresetService(name: "GitHub", category: .productivity, defaultAmount: 4000),
        PresetService(name: "Slack", category: .productivity, defaultAmount: 11000),
        PresetService(name: "Linear", category: .productivity, defaultAmount: 10000),
        PresetService(name: "Zoom", category: .productivity, defaultAmount: 18000),
        PresetService(name: "1Password", category: .productivity, defaultAmount: 4500),
        PresetService(name: "Adobe CC", category: .productivity, defaultAmount: 75000),
        PresetService(name: "Canva", category: .productivity, defaultAmount: 15000),
        PresetService(name: "iCloud+", category: .productivity, defaultAmount: 1100, iconName: nil),
        PresetService(name: "Google One", category: .productivity, defaultAmount: 2400),
    ]
}
