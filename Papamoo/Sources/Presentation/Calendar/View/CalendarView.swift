import SwiftUI
import SwiftData

struct CalendarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    monthlyHero
                    monthLineWithArrows
                    yellowRuler
                    MonthGridView(
                        displayedMonth: viewModel.displayedMonth,
                        displayedYear: viewModel.displayedYear,
                        eventDates: viewModel.eventDates,
                        selectedDay: $viewModel.selectedDay
                    )
                    .padding(.top, 4)

                    if viewModel.selectedDay != nil {
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
            .alert("구독 정보를 새로 고치지 못했어요", isPresented: $viewModel.isShowingFetchError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.fetchErrorMessage)
            }
        }
    }

    // MARK: - Monthly Hero

    private var monthlyHero: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(monthLabel().uppercased()) TOTAL")
                .font(.papamooMono(12, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(PapamooColor.textMuted)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(CurrencyFormatter.amountString(viewModel.monthTotal, currencyCode: viewModel.baseCurrency))
                    .font(.papamooMono(48, weight: .bold))
                    .foregroundStyle(PapamooColor.text)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(viewModel.baseCurrency)
                    .font(.papamooMono(16, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(PapamooColor.accent)
            }
            .padding(.top, 2)
            HStack(spacing: 18) {
                heroSplit(label: "PAID", value: viewModel.paidThisMonth, color: PapamooColor.textSubtle)
                heroSplit(label: "REMAINING", value: viewModel.remainingThisMonth, color: PapamooColor.accent)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private func heroSplit(label: String, value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.papamooMono(9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(PapamooColor.textMuted)
            Text(CurrencyFormatter.amountString(value, currencyCode: viewModel.baseCurrency))
                .font(.papamooMono(16, weight: .bold))
                .foregroundStyle(color)
                .monospacedDigit()
        }
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
