import CoreGraphics
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

enum PapamooMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PapamooSchemaV1.self, PapamooSchemaV2.self, PapamooSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: PapamooSchemaV1.self,
                toVersion: PapamooSchemaV2.self
            ),
            .lightweight(
                fromVersion: PapamooSchemaV2.self,
                toVersion: PapamooSchemaV3.self
            ),
        ]
    }
}
