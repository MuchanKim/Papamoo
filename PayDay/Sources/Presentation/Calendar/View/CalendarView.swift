import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    countdownHero
                    monthLineWithArrows
                    yellowRuler
                    MonthGridView(
                        displayedMonth: viewModel.displayedMonth,
                        displayedYear: viewModel.displayedYear,
                        eventDates: viewModel.eventDates,
                        selectedDay: $viewModel.selectedDay
                    )
                    .padding(.top, 4)

                    if viewModel.selectedDay == nil {
                        MonthlyTotalBar(
                            monthName: String(localized: "\(monthLabel()) Total"),
                            total: viewModel.monthTotal,
                            currencyCode: viewModel.baseCurrency
                        )
                        .padding(.top, 14)
                    } else {
                        MonthlyTotalBar(
                            monthName: String(localized: "PAYMENTS ON THIS DAY"),
                            total: viewModel.selectedDayTotal,
                            currencyCode: viewModel.baseCurrency
                        )
                        .padding(.top, 14)
                        ForEach(viewModel.selectedDaySubscriptions, id: \.persistentModelID) { sub in
                            SubscriptionRow(subscription: sub, baseCurrency: viewModel.baseCurrency)
                        }
                    }

                    Spacer(minLength: 24)
                }
            }
            .background(PayDayColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { viewModel.fetch() }
        }
    }

    // MARK: - Countdown Hero

    @ViewBuilder
    private var countdownHero: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT PAYMENT IN")
                .font(.payDayMono(12, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(PayDayColor.textMuted)
            if let next = viewModel.nextPayment {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(next.daysUntilNextPayment)")
                        .font(.payDayMono(48, weight: .bold))
                        .foregroundStyle(PayDayColor.accent)
                        .monospacedDigit()
                    Text("DAYS")
                        .font(.payDayMono(16, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(PayDayColor.textSubtle)
                }
                .padding(.top, 2)
                Text("\(next.name.uppercased()) · \(CurrencyFormatter.amountString(viewModel.nextPaymentDisplayAmount)) \(viewModel.baseCurrency)")
                    .font(.payDayMono(11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(PayDayColor.textMuted)
                    .padding(.top, 2)
            } else {
                Text("—")
                    .font(.payDayMono(48, weight: .bold))
                    .foregroundStyle(PayDayColor.textMuted)
                    .padding(.top, 2)
                Text("NO SUBSCRIPTIONS")
                    .font(.payDayMono(11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(PayDayColor.textMuted)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var monthLineWithArrows: some View {
        HStack {
            Text(monthLabel().uppercased() + " \(viewModel.displayedYear)")
                .font(.payDayMono(13, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(PayDayColor.textMuted)
            Spacer()
            HStack(spacing: 22) {
                Button { viewModel.changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PayDayColor.accent)
                }
                Button { viewModel.changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PayDayColor.accent)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var yellowRuler: some View {
        Rectangle()
            .fill(PayDayColor.ruler)
            .frame(height: 2)
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 12)
    }

    private func monthLabel() -> String {
        let components = DateComponents(year: viewModel.displayedYear, month: viewModel.displayedMonth)
        let date = Calendar.current.date(from: components)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}
