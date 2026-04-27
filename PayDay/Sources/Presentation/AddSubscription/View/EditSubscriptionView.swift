import SwiftUI

struct EditSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var subscription: Subscription
    var viewModel: AddSubscriptionViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    serviceHeader
                    planSection
                    noteSection
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
                    Button("Save") {
                        viewModel.update(subscription)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
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
                        Text(ExchangeRateManager.shared.currencySymbol(for: subscription.currencyCode))
                            .foregroundStyle(.secondary)
                        TextField("0", value: $subscription.amount, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .fontWeight(.semibold).monospacedDigit()
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Currency")
                    Spacer()
                    Picker("Currency", selection: $subscription.currencyCode) {
                        ForEach(ExchangeRateManager.shared.supportedCurrencies, id: \.self) { code in
                            Text("\(code) (\(ExchangeRateManager.shared.currencySymbol(for: code)))").tag(code)
                        }
                    }
                    .onChange(of: subscription.currencyCode) { subscription.amount = 0 }
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
            TextField("Optional", text: $subscription.note, axis: .vertical)
                .lineLimit(3...)
                .padding(14)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.delete(subscription)
            dismiss()
        } label: {
            Text("Delete subscription")
                .font(.body)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .padding(.top, 24)
    }
}
