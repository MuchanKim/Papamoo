import SwiftUI
import SwiftData

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
            .background(PapamooColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { viewModel.fetch() }
        }
    }

    // MARK: - Countdown Hero

    @ViewBuilder
    private var countdownHero: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT PAYMENT IN")
                .font(.papamooMono(12, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(PapamooColor.textMuted)
            if let next = viewModel.nextPayment {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(next.daysUntilNextPayment)")
                        .font(.papamooMono(48, weight: .bold))
                        .foregroundStyle(PapamooColor.accent)
                        .monospacedDigit()
                    Text("DAYS")
                        .font(.papamooMono(16, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(PapamooColor.textSubtle)
                }
                .padding(.top, 2)
                Text("\(next.name.uppercased()) · \(CurrencyFormatter.amountString(viewModel.nextPaymentDisplayAmount)) \(viewModel.baseCurrency)")
                    .font(.papamooMono(11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(PapamooColor.textMuted)
                    .padding(.top, 2)
            } else {
                Text("—")
                    .font(.papamooMono(48, weight: .bold))
                    .foregroundStyle(PapamooColor.textMuted)
                    .padding(.top, 2)
                Text("NO SUBSCRIPTIONS")
                    .font(.papamooMono(11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(PapamooColor.textMuted)
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
                .font(.papamooMono(13, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(PapamooColor.textMuted)
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
        .padding(.top, 14)
    }

    private var yellowRuler: some View {
        Rectangle()
            .fill(PapamooColor.ruler)
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
