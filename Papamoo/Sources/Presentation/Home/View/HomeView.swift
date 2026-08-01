import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var coordinator: AppCoordinator
    @Bindable var viewModel: HomeViewModel
    let factory: ViewModelFactory
    @State private var isShowingAddActions = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
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

                if isShowingAddActions {
                    Color.clear
                        .contentShape(.rect)
                        .ignoresSafeArea()
                        .onTapGesture { dismissAddActions() }
                }

                addActions
                    .allowsHitTesting(isShowingAddActions)
                    .accessibilityHidden(isShowingAddActions == false)
                    .zIndex(1)
            }
            .background(PapamooColor.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.78)) {
                            isShowingAddActions.toggle()
                        }
                    } label: {
                        Image(systemName: isShowingAddActions ? "xmark" : "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(PapamooColor.accent)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel(isShowingAddActions ? "Close add menu" : "Add subscription")
                    .accessibilityIdentifier("home.add-menu")
                }
            }
            .sheet(isPresented: $coordinator.isShowingAddSheet, onDismiss: {
                viewModel.fetch()
            }) {
                AddSubscriptionSearchView(
                    coordinator: coordinator,
                    viewModel: factory.makeAddSubscriptionViewModel()
                )
            }
            .fullScreenCover(
                isPresented: $coordinator.isShowingCamera,
                onDismiss: coordinator.finishCameraPresentation
            ) {
                CameraImagePicker(
                    onImagePicked: coordinator.selectImageForImport,
                    onCancel: coordinator.cancelCamera
                )
                .ignoresSafeArea()
            }
            .sheet(item: $coordinator.imageImportSelection, onDismiss: {
                viewModel.fetch()
            }) { selection in
                ShareRootView(
                    viewModel: factory.makeImageImportViewModel(
                        imageData: selection.data,
                        onComplete: coordinator.dismissImageImport,
                        onCancel: coordinator.dismissImageImport
                    )
                )
            }
            .sheet(item: $coordinator.selectedSubscription, onDismiss: {
                viewModel.fetch()
            }) { subscription in
                EditSubscriptionView(
                    subscription: subscription,
                    viewModel: factory.makeAddSubscriptionViewModel(),
                    onDelete: viewModel.removeSubscription(withID:)
                )
            }
            .onAppear { viewModel.fetch() }
            .alert("구독 정보를 새로 고치지 못했어요", isPresented: $viewModel.isShowingFetchError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.fetchErrorMessage)
            }
        }
    }

    private var addActions: some View {
        VStack(spacing: 6) {
            addActionButton(
                systemName: "camera",
                accessibilityLabel: "Take a payment photo",
                action: showCamera
            )
            addActionButton(
                systemName: "pencil",
                accessibilityLabel: "Enter subscription manually",
                action: showDirectEntry
            )
        }
        .padding(.top, 6)
        .padding(.trailing, 16)
    }

    private func addActionButton(
        systemName: String,
        accessibilityLabel: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(PapamooColor.text)
                .frame(width: 44, height: 44)
                .background(PapamooColor.surface, in: Circle())
                .overlay {
                    Circle().stroke(PapamooColor.dividerSoft, lineWidth: 1)
                }
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("home.add-\(systemName)")
        .scaleEffect(isShowingAddActions ? 1 : 0.72)
        .opacity(isShowingAddActions ? 1 : 0)
    }

    private func showCamera() {
        dismissAddActions()
        coordinator.showCamera()
    }

    private func showDirectEntry() {
        dismissAddActions()
        coordinator.showAddSubscription()
    }

    private func dismissAddActions() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            isShowingAddActions = false
        }
    }

    private var topNav: some View {
        Text(monthName())
            .font(.papamooMono(13, weight: .bold))
            .tracking(1.4)
            .foregroundStyle(PapamooColor.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 12)
    }

    private var megaAmount: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(CurrencyFormatter.amountString(viewModel.remainingThisMonth, currencyCode: viewModel.baseCurrency))
                .font(.papamooDisplay)
                .foregroundStyle(PapamooColor.text)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(viewModel.baseCurrency)
                .font(.papamooMono(20, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(PapamooColor.accent)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    private var metaLine: some View {
        Text("REMAINING · \(CurrencyFormatter.amountString(viewModel.paidThisMonth, currencyCode: viewModel.baseCurrency)) PAID · \(CurrencyFormatter.amountString(viewModel.monthlyTotal, currencyCode: viewModel.baseCurrency)) TOTAL")
            .font(.papamooMeta)
            .foregroundStyle(PapamooColor.textMuted)
            .tracking(0.4)
            .padding(.horizontal, 18)
            .padding(.top, 8)
    }

    private var yellowRuler: some View {
        Rectangle()
            .fill(PapamooColor.ruler)
            .frame(height: 2)
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 18)
    }

    @ViewBuilder
    private var upcomingSection: some View {
        if !viewModel.upcomingSubscriptions.isEmpty {
            upcomingHeader
            ForEach(viewModel.upcomingSubscriptions, id: \.persistentModelID) { sub in
                Button { coordinator.selectSubscription(sub) } label: {
                    SubscriptionRow(
                        subscription: sub,
                        baseCurrency: viewModel.baseCurrency,
                        showDday: sub.daysUntilNextPayment <= 3
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var upcomingHeader: some View {
        HStack(spacing: 8) {
            Text("UPCOMING")
                .font(.papamooMeta)
                .foregroundStyle(PapamooColor.textMuted)
                .tracking(1.4)
            Spacer()
            rateRefresh
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var rateRefresh: some View {
        let manager = ExchangeRateManager.shared
        return HStack(spacing: 6) {
            Text("$1=₩\(manager.krwPerUSD.formatted()) · ¥\(manager.jpyPerUSD.formatted())")
                .font(.papamooMono(9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(PapamooColor.textMuted)
            Button {
                Task { await manager.fetchLatestRates() }
            } label: {
                if manager.isLoading {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(PapamooColor.accent)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(PapamooColor.accent)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func monthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: .now).uppercased()
    }
}
