import SwiftUI

struct AddSubscriptionDetailView: View {

    // MARK: - Properties

    @Bindable var coordinator: AppCoordinator
    @Bindable var viewModel: AddSubscriptionViewModel
    @State private var isSaving = false
    @State private var isShowingSaveError = false
    @State private var saveErrorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                serviceHeader
                planSection
                noteSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            addButton
        }
        .navigationTitle(viewModel.name.isEmpty ? "New service" : viewModel.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("구독을 저장하지 못했어요", isPresented: $isShowingSaveError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(saveErrorMessage)
        }
    }

    private var serviceHeader: some View {
        VStack(spacing: 10) {
            ServiceIconView(
                category: viewModel.category,
                iconName: viewModel.iconName,
                size: 72
            )
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
                        TextField(
                            "0",
                            value: $viewModel.amount,
                            format: .number.precision(
                                .fractionLength(0...CurrencyFormatter.maximumFractionDigits(for: viewModel.currencyCode))
                            )
                        )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.papamooAmount)
                            .monospacedDigit()
                        Text(viewModel.currencyCode)
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
                    Picker("Currency", selection: $viewModel.currencyCode) {
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
            TextField("Optional. Add a note for context — e.g., shared with family, promo until Dec.", text: $viewModel.note, axis: .vertical)
                .lineLimit(4...)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(PapamooColor.surface, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
        }
    }

    private var addButton: some View {
        Button(action: saveSubscription) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(PapamooColor.background)
                }
                Text(addButtonTitle)
            }
            .font(.papamooMono(13, weight: .bold))
            .tracking(1.0)
            .foregroundStyle(PapamooColor.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(PapamooColor.accent, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!viewModel.isFormValid || isSaving)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    private var addButtonTitle: LocalizedStringResource {
        isSaving ? "SAVING" : "ADD SUBSCRIPTION"
    }

    // MARK: - Private Methods

    private func saveSubscription() {
        guard isSaving == false else { return }
        isSaving = true

        Task {
            await Task.yield()
            do {
                try viewModel.save()
                coordinator.dismissAddSubscription()
            } catch {
                saveErrorMessage = error.localizedDescription
                isShowingSaveError = true
                isSaving = false
            }
        }
    }
}
