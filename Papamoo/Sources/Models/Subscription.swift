import CoreGraphics
import Foundation
import SwiftData

enum PapamooSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Subscription.self] }

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
        @Attribute(.externalStorage) var sourceImageData: Data?
        var sourceCropX: Double?
        var sourceCropY: Double?
        var sourceCropWidth: Double?
        var sourceCropHeight: Double?

        init(
            name: String,
            amount: Decimal,
            currencyCode: String = "KRW",
            billingCycle: BillingCycle = .monthly,
            firstPaymentDate: Date,
            category: SubscriptionCategory = .other,
            note: String = "",
            iconName: String? = nil,
            sourceImageData: Data? = nil,
            sourceCropRegion: CGRect? = nil
        ) {
            self.name = name
            self.amount = amount
            self.currencyCode = currencyCode
            self.billingCycle = billingCycle
            self.firstPaymentDate = firstPaymentDate
            self.category = category
            self.note = note
            self.iconName = iconName
            self.sourceImageData = sourceImageData
            self.sourceCropX = sourceCropRegion.map { Double($0.minX) }
            self.sourceCropY = sourceCropRegion.map { Double($0.minY) }
            self.sourceCropWidth = sourceCropRegion.map { Double($0.width) }
            self.sourceCropHeight = sourceCropRegion.map { Double($0.height) }
        }
    }
}

typealias Subscription = PapamooSchemaV2.Subscription

extension Subscription {

    var sourceCropRegion: CGRect? {
        guard let sourceCropX,
              let sourceCropY,
              let sourceCropWidth,
              let sourceCropHeight
        else { return nil }

        return CGRect(
            x: CGFloat(sourceCropX),
            y: CGFloat(sourceCropY),
            width: CGFloat(sourceCropWidth),
            height: CGFloat(sourceCropHeight)
        )
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

    static func isValid(name: String, amount: Decimal) -> Bool {
        !name.isEmpty && amount > 0
    }

    var isValid: Bool { Self.isValid(name: name, amount: amount) }
}
