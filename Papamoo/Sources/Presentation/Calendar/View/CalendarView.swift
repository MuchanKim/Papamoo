import SwiftUI
import SwiftData

struct CalendarView: View {

    // MARK: - Properties

    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    monthSummary
                    yellowRuler
                    MonthGridView(
                        displayedMonth: viewModel.displayedMonth,
                        displayedYear: viewModel.displayedYear,
                        dailyTotals: viewModel.dailyTotals,
                        currencyCode: viewModel.baseCurrency,
                        selectedDay: $viewModel.selectedDay
                    )
                    .padding(.top, 4)

                    if let selectedDate = viewModel.selectedDate {
                        selectedDaySection(date: selectedDate)
                            .padding(.top, 18)
                    }

                    Spacer(minLength: 24)
                }
            }
            .background(PapamooColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var monthSummary: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(monthLabel() + " \(viewModel.displayedYear)")
                    .font(.papamooMono(22, weight: .bold))
                    .foregroundStyle(PapamooColor.textSubtle)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("TOTAL")
                        .font(.papamooMono(11, weight: .bold))
                        .foregroundStyle(PapamooColor.textMuted)
                    Text(CurrencyFormatter.amountString(viewModel.monthTotal, currencyCode: viewModel.baseCurrency))
                        .font(.papamooMono(16, weight: .bold))
                        .foregroundStyle(PapamooColor.accent)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(viewModel.baseCurrency)
                        .font(.papamooMono(12, weight: .bold))
                        .foregroundStyle(PapamooColor.accent)
                    Text("·")
                        .foregroundStyle(PapamooColor.textMuted)
                    paymentCountLabel(viewModel.monthPaymentCount)
                }
            }
            Spacer()
            HStack(spacing: 22) {
                Button { viewModel.changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PapamooColor.accent)
                }
                Button { viewModel.changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PapamooColor.accent)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
    }

    private var yellowRuler: some View {
        Rectangle()
            .fill(PapamooColor.ruler)
            .frame(height: 2)
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 12)
    }

    // MARK: - Private Methods

    private func selectedDaySection(date: Date) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(date.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                    .font(.papamooMono(20, weight: .bold))
                    .foregroundStyle(PapamooColor.text)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(CurrencyFormatter.amountString(viewModel.selectedDayTotal, currencyCode: viewModel.baseCurrency))
                        .font(.papamooMono(16, weight: .bold))
                        .foregroundStyle(PapamooColor.accent)
                        .monospacedDigit()
                    Text(viewModel.baseCurrency)
                        .font(.papamooMono(12, weight: .bold))
                        .foregroundStyle(PapamooColor.accent)
                    Text("·")
                        .foregroundStyle(PapamooColor.textMuted)
                    paymentCountLabel(viewModel.selectedDaySubscriptions.count)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Rectangle()
                .fill(PapamooColor.dividerSoft)
                .frame(height: 1)
                .padding(.horizontal, 20)

            ForEach(viewModel.selectedDaySubscriptions, id: \.persistentModelID) { subscription in
                calendarSubscriptionRow(subscription)
            }
        }
    }

    private func calendarSubscriptionRow(_ subscription: Subscription) -> some View {
        HStack(spacing: 14) {
            ServiceIconView(
                category: subscription.category,
                iconName: subscription.iconName,
                size: 44
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(subscription.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PapamooColor.text)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(CurrencyFormatter.amountString(
                        ExchangeRateManager.shared.convertToBase(
                            amount: subscription.amount,
                            from: subscription.currencyCode
                        ),
                        currencyCode: viewModel.baseCurrency
                    ))
                    .font(.papamooMono(15, weight: .bold))
                    .foregroundStyle(PapamooColor.accent)
                    .monospacedDigit()
                    Text(viewModel.baseCurrency)
                        .font(.papamooMono(10, weight: .bold))
                        .foregroundStyle(PapamooColor.accent)
                }
            }

            Spacer(minLength: 8)

            Text(subscription.billingCycle.displayName)
                .font(.papamooMono(11, weight: .medium))
                .foregroundStyle(PapamooColor.textMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func paymentCountLabel(_ count: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(count)")
                .monospacedDigit()
            if count == 1 {
                Text("PAYMENT")
            } else {
                Text("PAYMENTS")
            }
        }
        .font(.papamooMono(11, weight: .bold))
        .foregroundStyle(PapamooColor.textMuted)
    }

    private func monthLabel() -> String {
        let components = DateComponents(year: viewModel.displayedYear, month: viewModel.displayedMonth)
        let date = Calendar.current.date(from: components)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}
