import SwiftUI

struct HomeView: View {
    @Bindable var coordinator: AppCoordinator
    var viewModel: HomeViewModel

    @State private var isShowingExchangeRate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topNav
                    megaAmount
                    metaLine
                    yellowRuler
                    nextPaymentSection
                    upcomingSection
                }
                .padding(.bottom, 16)
            }
            .background(PayDayColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $coordinator.isShowingAddSheet, onDismiss: {
                viewModel.fetch()
            }) {
                AddSubscriptionSearchView(
                    coordinator: coordinator,
                    viewModel: coordinator.makeAddSubscriptionViewModel()
                )
            }
            .sheet(item: $coordinator.selectedSubscription, onDismiss: {
                viewModel.fetch()
            }) { subscription in
                EditSubscriptionView(
                    subscription: subscription,
                    viewModel: coordinator.makeAddSubscriptionViewModel()
                )
            }
            .sheet(isPresented: $isShowingExchangeRate, onDismiss: {
                viewModel.fetch()
            }) {
                ExchangeRateSheetView()
                    .presentationDetents([.medium])
            }
            .onAppear { viewModel.fetch() }
        }
    }

    private var topNav: some View {
        HStack {
            Text("PAYDAY · \(monthName())")
                .font(.payDayMeta)
                .foregroundStyle(PayDayColor.textMuted)
                .tracking(1.4)
            Spacer()
            Button { coordinator.showAddSubscription() } label: {
                Text("+")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(PayDayColor.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var megaAmount: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(currencySymbol(for: viewModel.baseCurrency))
                .font(.payDayDisplay)
                .foregroundStyle(PayDayColor.accent)
            Text(amountString(viewModel.remainingThisMonth))
                .font(.payDayDisplay)
                .foregroundStyle(PayDayColor.text)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var metaLine: some View {
        Text("REMAINING · \(amountString(viewModel.paidThisMonth)) PAID · \(amountString(viewModel.monthlyTotal)) TOTAL")
            .font(.payDayMeta)
            .foregroundStyle(PayDayColor.textMuted)
            .tracking(0.4)
            .padding(.horizontal, 16)
            .padding(.top, 4)
    }

    private var yellowRuler: some View {
        Rectangle()
            .fill(PayDayColor.ruler)
            .frame(height: 2)
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 14)
    }

    @ViewBuilder
    private var nextPaymentSection: some View {
        if let nextPayment = viewModel.nextPayment {
            sectionLabel("NEXT PAYMENT")
            Button { coordinator.selectSubscription(nextPayment) } label: {
                SubscriptionRow(
                    subscription: nextPayment,
                    baseCurrency: viewModel.baseCurrency,
                    showDday: true
                )
            }
            .buttonStyle(.plain)
            Rectangle()
                .fill(PayDayColor.dividerSoft)
                .frame(height: 1)
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        if !viewModel.upcomingSubscriptions.isEmpty {
            sectionLabel("UPCOMING")
            ForEach(viewModel.upcomingSubscriptions, id: \.persistentModelID) { sub in
                Button { coordinator.selectSubscription(sub) } label: {
                    SubscriptionRow(subscription: sub, baseCurrency: viewModel.baseCurrency)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.payDayMeta)
            .foregroundStyle(PayDayColor.textMuted)
            .tracking(1.4)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func currencySymbol(for code: String) -> String {
        switch code {
        case "KRW": "₩"
        case "USD": "$"
        case "JPY": "¥"
        default: code
        }
    }

    private func amountString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(for: value) ?? "0"
    }

    private func monthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: .now).uppercased()
    }
}
