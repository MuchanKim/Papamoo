import SwiftUI

struct SharePlanFieldsView: View {

    @Environment(\.locale) private var locale

    @Binding var amountText: String
    @Binding var currencyCode: String
    @Binding var billingCycle: BillingCycle
    @Binding var firstPaymentDate: Date
    @Binding var category: SubscriptionCategory
    let supportedCurrencies: [String]

    var body: some View {
        VStack(spacing: 0) {
            amountRow
            rowDivider
            currencyRow
            rowDivider
            billingCycleRow
            rowDivider
            dateRow
            rowDivider
            categoryRow
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .tint(.primary)
    }

    private var amountRow: some View {
        HStack {
            Text("Amount")
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: $amountText)
                    .font(.shareAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                Text(currencyCode)
                    .font(.papamooMono(10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var currencyRow: some View {
        HStack {
            Text("Currency")
            Spacer()
            Picker("Currency", selection: $currencyCode) {
                ForEach(supportedCurrencies, id: \.self) { code in
                    Text("\(code) (\(CurrencyFormatter.symbol(for: code)))").tag(code)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var billingCycleRow: some View {
        HStack {
            Text("Billing")
            Spacer()
            Picker("Billing", selection: $billingCycle) {
                ForEach(BillingCycle.allCases, id: \.self) { cycle in
                    Text(cycle.displayName.localized(for: locale)).tag(cycle)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var dateRow: some View {
        DatePicker(
            "First payment",
            selection: $firstPaymentDate,
            displayedComponents: .date
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var categoryRow: some View {
        HStack {
            Text("Category")
            Spacer()
            Picker("Category", selection: $category) {
                ForEach(SubscriptionCategory.allCases, id: \.self) { item in
                    Text(item.displayName.localized(for: locale)).tag(item)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 16)
    }
}
