import SwiftData

@ModelActor
actor PendingSubscriptionImportStore {

    // MARK: - Properties

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

    // MARK: - Methods

    func importPendingSubscriptions() throws -> Int {
        let entries = try inbox.entries()
        guard entries.isEmpty == false else { return 0 }

        var knownImportIDs = Set(
            try modelContext.fetch(FetchDescriptor<Subscription>())
                .compactMap(\.sourceImportID)
        )
        var importedCount = 0

        for entry in entries {
            let payload = entry.payload
            guard knownImportIDs.insert(payload.id).inserted else { continue }

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
                    sourceCropRegion: payload.sourceCropRegion,
                    sourceImportID: payload.id
                )
            )
            importedCount += 1
        }

        if importedCount > 0 {
            do {
                try modelContext.save()
            } catch {
                modelContext.rollback()
                throw error
            }
        }

        try inbox.remove(entries)
        return importedCount
    }
}
