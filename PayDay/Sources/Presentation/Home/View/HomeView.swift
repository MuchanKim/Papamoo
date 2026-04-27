import SwiftUI

struct HomeView: View {
    @Bindable var coordinator: AppCoordinator
    var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    nextPaymentSection
                    upcomingSection
                }
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Subs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { coordinator.showAddSubscription() } label: {
                        Image(systemName: "plus")
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
            .onAppear { viewModel.fetch() }
        }
    }

    // MARK: - Hero

    @State private var isShowingExchangeRate = false

    private var heroSection: some View {
        VStack(spacing: 6) {
            HeroSummaryCard(
                remainingAmount: viewModel.remainingThisMonth,
                paidAmount: viewModel.paidThisMonth,
                totalAmount: viewModel.monthlyTotal,
                currencyCode: viewModel.baseCurrency
            )

            if viewModel.hasMultipleCurrencies {
                Button { isShowingExchangeRate = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "yensign.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 10))
                        Text("Exchange rates")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .sheet(isPresented: $isShowingExchangeRate, onDismiss: {
            viewModel.fetch()
        }) {
            ExchangeRateSheetView()
                .presentationDetents([.medium])
        }
    }

    // MARK: - Next Payment

    @ViewBuilder
    private var nextPaymentSection: some View {
        if let nextPayment = viewModel.nextPayment {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeaderView(title: "Next payment")
                subscriptionCard(for: nextPayment, showDday: true)
            }
        }
    }

    // MARK: - Upcoming

    @ViewBuilder
    private var upcomingSection: some View {
        if !viewModel.upcomingSubscriptions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeaderView(title: "Upcoming")
                VStack(spacing: 6) {
                    ForEach(viewModel.upcomingSubscriptions, id: \.persistentModelID) { sub in
                        subscriptionCard(for: sub)
                    }
                }
            }
        }
    }

    // MARK: - Shared Card Builder

    private func subscriptionCard(for subscription: Subscription, showDday: Bool = false) -> some View {
        Button { coordinator.selectSubscription(subscription) } label: {
            SubscriptionRow(subscription: subscription, baseCurrency: viewModel.baseCurrency, showDday: showDday)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
        .padding(.horizontal, 16)
    }
}
