import Foundation
import SwiftData

enum PapamooSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
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

        init(
            name: String,
            amount: Decimal,
            currencyCode: String = "KRW",
            billingCycle: BillingCycle = .monthly,
            firstPaymentDate: Date,
            category: SubscriptionCategory = .other,
            note: String = "",
            iconName: String? = nil
        ) {
            self.name = name
            self.amount = amount
            self.currencyCode = currencyCode
            self.billingCycle = billingCycle
            self.firstPaymentDate = firstPaymentDate
            self.category = category
            self.note = note
            self.iconName = iconName
        }
    }
}

enum PapamooMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PapamooSchemaV1.self, PapamooSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: PapamooSchemaV1.self,
                toVersion: PapamooSchemaV2.self
            ),
        ]
    }
}
