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
                    upcomingSection
                }
                .padding(.bottom, 16)
            }
            .background(PayDayColor.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { coordinator.showAddSubscription() } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(PayDayColor.accent)
                    }
                }
            }
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
        Text("PAYDAY · \(monthName())")
            .font(.payDayMeta)
            .foregroundStyle(PayDayColor.textMuted)
            .tracking(1.4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 4)
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
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    private var metaLine: some View {
        Text("REMAINING · \(amountString(viewModel.paidThisMonth)) PAID · \(amountString(viewModel.monthlyTotal)) TOTAL")
            .font(.payDayMeta)
            .foregroundStyle(PayDayColor.textMuted)
            .tracking(0.4)
            .padding(.horizontal, 18)
            .padding(.top, 8)
    }

    private var yellowRuler: some View {
        Rectangle()
            .fill(PayDayColor.ruler)
            .frame(height: 2)
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 18)
    }

    @ViewBuilder
    private var upcomingSection: some View {
        if !viewModel.upcomingSubscriptions.isEmpty {
            sectionLabel("UPCOMING")
            ForEach(Array(viewModel.upcomingSubscriptions.enumerated()), id: \.element.persistentModelID) { index, sub in
                Button { coordinator.selectSubscription(sub) } label: {
                    SubscriptionRow(
                        subscription: sub,
                        baseCurrency: viewModel.baseCurrency,
                        showDday: index == 0
                    )
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
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 6)
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
