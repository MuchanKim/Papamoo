import SwiftUI

struct AddSubscriptionDetailView: View {
    @Bindable var coordinator: AppCoordinator
    @Bindable var viewModel: AddSubscriptionViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                serviceHeader
                planSection
                noteSection
                addButton
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.name.isEmpty ? "New service" : viewModel.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if viewModel.save() {
                        coordinator.dismissAddSubscription()
                    }
                } label: {
                    Text("SAVE")
                        .font(.payDayMono(13, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(PayDayColor.accent)
                }
                .disabled(!viewModel.isFormValid)
            }
        }
    }

    private var serviceHeader: some View {
        VStack(spacing: 10) {
            ServiceIconView(category: viewModel.category, iconName: viewModel.selectedPreset?.iconName, size: 72)
            if viewModel.selectedPreset?.name.isEmpty == true {
                TextField("Service name", text: $viewModel.name)
                    .font(.title2).fontWeight(.bold)
                    .multilineTextAlignment(.center)
            } else {
                Text(viewModel.name).font(.title2).fontWeight(.bold)
            }
            Text(viewModel.category.displayName).font(.footnote).foregroundStyle(.tertiary)
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
                        Text(ExchangeRateManager.shared.currencySymbol(for: viewModel.currencyCode))
                            .font(.payDayAmount)
                            .foregroundStyle(PayDayColor.accent)
                        TextField("0", value: $viewModel.amount, format: .number.precision(.fractionLength(0)))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.payDayAmount)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Currency")
                    Spacer()
                    Picker("Currency", selection: $viewModel.currencyCode) {
                        ForEach(ExchangeRateManager.shared.supportedCurrencies, id: \.self) { code in
                            Text("\(code) (\(ExchangeRateManager.shared.currencySymbol(for: code)))").tag(code)
                        }
                    }
                    .onChange(of: viewModel.currencyCode) { viewModel.amount = 0 }
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Billing")
                    Spacer()
                    Picker("Billing", selection: $viewModel.billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Text(cycle.displayName).tag(cycle)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                DatePicker("First payment", selection: $viewModel.firstPaymentDate, displayedComponents: .date)
                    .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Category")
                    Spacer()
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
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
            TextField("Optional · e.g. \"Family plan\"", text: $viewModel.note, axis: .vertical)
                .lineLimit(3...)
                .padding(14)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
        }
    }

    private var addButton: some View {
        Button {
            if viewModel.save() {
                coordinator.dismissAddSubscription()
            }
        } label: {
            Text("ADD SUBSCRIPTION")
                .font(.payDayMono(13, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(PayDayColor.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(PayDayColor.accent, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!viewModel.isFormValid)
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}
