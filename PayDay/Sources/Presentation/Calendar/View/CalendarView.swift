import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    topNav
                    monthTitle
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
                            monthName: "\(monthNameFull()) Total",
                            total: viewModel.monthTotal,
                            currencyCode: viewModel.baseCurrency
                        )
                        .padding(.top, 14)
                        Text("TAP A DAY TO SEE PAYMENTS")
                            .font(.payDayMeta)
                            .foregroundStyle(PayDayColor.textMuted)
                            .tracking(1.4)
                            .padding(.horizontal, 18)
                            .padding(.top, 12)
                    } else {
                        MonthlyTotalBar(
                            monthName: "\(monthNameFull()) \(viewModel.selectedDay ?? 0) · Selected",
                            total: selectedDayTotal,
                            currencyCode: viewModel.baseCurrency
                        )
                        .padding(.top, 14)
                        Text("PAYMENTS ON THIS DAY")
                            .font(.payDayMeta)
                            .foregroundStyle(PayDayColor.textMuted)
                            .tracking(1.4)
                            .padding(.horizontal, 18)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
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

    private var topNav: some View {
        HStack {
            Button { viewModel.changeMonth(by: -1) } label: {
                Text("‹")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(PayDayColor.accent)
            }
            Spacer()
            Text("CALENDAR")
                .font(.payDayMeta)
                .foregroundStyle(PayDayColor.textMuted)
                .tracking(1.4)
            Spacer()
            Button { viewModel.changeMonth(by: 1) } label: {
                Text("›")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(PayDayColor.accent)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var monthTitle: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(monthNameFull())
                .font(.payDayTitle)
                .foregroundStyle(PayDayColor.text)
            Text(String(viewModel.displayedYear))
                .font(.payDayTitle)
                .foregroundStyle(PayDayColor.textMuted)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private var yellowRuler: some View {
        Rectangle()
            .fill(PayDayColor.ruler)
            .frame(height: 2)
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 12)
    }

    private var selectedDayTotal: Decimal {
        viewModel.selectedDaySubscriptions.reduce(Decimal.zero) { total, sub in
            total + ExchangeRateManager.shared.convertToBase(amount: sub.amount, from: sub.currencyCode)
        }
    }

    private func monthNameFull() -> String {
        let components = DateComponents(year: viewModel.displayedYear, month: viewModel.displayedMonth)
        let date = Calendar.current.date(from: components)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}
