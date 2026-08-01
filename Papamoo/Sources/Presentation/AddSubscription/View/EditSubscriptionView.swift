import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var subscription: Subscription
    var viewModel: AddSubscriptionViewModel
    let onDelete: (PersistentIdentifier) -> Void
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var isShowingOperationError = false
    @State private var operationErrorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    serviceHeader
                    planSection
                    noteSection
                    if let sourceImageData = subscription.sourceImageData {
                        SubscriptionSourceDocumentView(imageData: sourceImageData)
                    }
                    deleteButton
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(subscription.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveSubscription()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .tint(PapamooColor.accent)
                        } else {
                            Text("SAVE")
                                .font(.papamooMono(13, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(PapamooColor.accent)
                        }
                    }
                    .disabled(!subscription.isValid || isSaving || isDeleting)
                }
            }
        }
        .interactiveDismissDisabled(isSaving || isDeleting)
        .alert("작업을 완료하지 못했어요", isPresented: $isShowingOperationError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(operationErrorMessage)
        }
    }

    private var serviceHeader: some View {
        VStack(spacing: 10) {
            ServiceIconView(category: subscription.category, iconName: subscription.iconName, size: 72)
            Text(subscription.name).font(.title2).fontWeight(.bold)
            Text(subscription.category.displayName).font(.footnote).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 20)
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plan").font(.footnote).fontWeight(.semibold).foregroundStyle(.tertiary).padding(.leading, 20)
            VStack(spacing: 0) {
                HStack {
                    Text("Amount")
                    Spacer()
                    HStack(spacing: 4) {
                        TextField(
                            "0",
                            value: $subscription.amount,
                            format: .number.precision(
                                .fractionLength(0...CurrencyFormatter.maximumFractionDigits(for: subscription.currencyCode))
                            )
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.papamooAmount)
                            .monospacedDigit()
                        Text(subscription.currencyCode)
                            .font(.papamooMono(10, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(PapamooColor.accent)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Currency")
                    Spacer()
                    Picker("Currency", selection: $subscription.currencyCode) {
                        ForEach(viewModel.supportedCurrencies, id: \.self) { code in
                            Text(viewModel.currencyLabel(for: code)).tag(code)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Billing")
                    Spacer()
                    Picker("Billing", selection: $subscription.billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }.pickerStyle(.segmented).frame(width: 160)
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                DatePicker("First payment", selection: $subscription.firstPaymentDate, displayedComponents: .date)
                    .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Category")
                    Spacer()
                    Picker("Category", selection: $subscription.category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 11)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note").font(.footnote).fontWeight(.semibold).foregroundStyle(.tertiary).padding(.leading, 20).padding(.top, 20)
            TextField("Optional. Add a note for context — e.g., shared with family, promo until Dec.", text: $subscription.note, axis: .vertical)
                .lineLimit(4...)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(PapamooColor.surface, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive, action: deleteSubscription) {
            HStack(spacing: 8) {
                if isDeleting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.red)
                } else {
                    Image(systemName: "trash")
                }
                Text(isDeleting ? "Deleting…" : "Delete subscription")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(PapamooColor.surface, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isSaving || isDeleting)
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private func saveSubscription() {
        guard isSaving == false, isDeleting == false else { return }
        isSaving = true

        Task {
            await Task.yield()
            do {
                try viewModel.update(subscription)
                dismiss()
            } catch {
                operationErrorMessage = error.localizedDescription
                isShowingOperationError = true
                isSaving = false
            }
        }
    }

    private func deleteSubscription() {
        guard isSaving == false, isDeleting == false else { return }
        let subscriptionID = subscription.persistentModelID
        isDeleting = true

        Task {
            await Task.yield()
            do {
                try await viewModel.delete(id: subscriptionID)
                onDelete(subscriptionID)
                dismiss()
            } catch {
                operationErrorMessage = error.localizedDescription
                isShowingOperationError = true
                isDeleting = false
            }
        }
    }
}
