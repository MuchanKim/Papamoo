import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigationHeader
                MonthGridView(
                    year: viewModel.displayedYear,
                    month: viewModel.displayedMonth,
                    eventDates: viewModel.eventDates,
                    selectedDay: $viewModel.selectedDay
                )

                if !viewModel.selectedDaySubscriptions.isEmpty {
                    selectedDayDetail
                }

                Spacer()

                MonthlyTotalBar(monthName: viewModel.monthName, total: viewModel.monthTotal)
                    .padding(.bottom, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .onAppear { viewModel.fetch() }
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Text("\(viewModel.monthName) \(String(viewModel.displayedYear))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(PayDayColor.brand)
            Spacer()
            HStack(spacing: 22) {
                Button { viewModel.changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundStyle(PayDayColor.brand)
                }
                Button { viewModel.changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .foregroundStyle(PayDayColor.brand)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Selected Day Detail

    @ViewBuilder
    private var selectedDayDetail: some View {
        let calendar = Calendar.current
        let components = DateComponents(year: viewModel.displayedYear, month: viewModel.displayedMonth, day: viewModel.selectedDay)
        let date = calendar.date(from: components)

        VStack(alignment: .leading, spacing: 8) {
            if let date {
                Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 20)
                    .padding(.top, 16)
            }

            VStack(spacing: 6) {
                ForEach(viewModel.selectedDaySubscriptions, id: \.persistentModelID) { sub in
                    SubscriptionRow(subscription: sub)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.background, in: RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}
