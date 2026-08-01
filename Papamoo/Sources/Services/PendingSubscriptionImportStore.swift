import SwiftData

@ModelActor
actor PendingSubscriptionImportStore {
    private var inbox = SubscriptionImportInbox()

    init(
        modelContainer: ModelContainer,
        inbox: SubscriptionImportInbox = SubscriptionImportInbox()
    ) {
        let context = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.modelContainer = modelContainer
        self.inbox = inbox
    }

    func importPendingSubscriptions() throws -> Int {
        let entries = try inbox.entries()
        guard entries.isEmpty == false else { return 0 }

        for entry in entries {
            let payload = entry.payload
            modelContext.insert(
                Subscription(
                    name: payload.name,
                    amount: payload.amount,
                    currencyCode: payload.currencyCode,
                    billingCycle: payload.billingCycle,
                    firstPaymentDate: payload.firstPaymentDate,
                    category: payload.category,
                    note: payload.note,
                    iconName: payload.iconName,
                    sourceImageData: payload.sourceImageData,
                    sourceCropRegion: payload.sourceCropRegion
                )
            )
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }

        try inbox.remove(entries)
        return entries.count
    }
}
