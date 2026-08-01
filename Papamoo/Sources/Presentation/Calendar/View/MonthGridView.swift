import SwiftUI

struct MonthGridView: View {
    let displayedMonth: Int
    let displayedYear: Int
    let dailyTotals: [Int: Decimal]
    let currencyCode: String
    @Binding var selectedDay: Int?

    private var calendar: Calendar { Calendar.current }
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    private var firstWeekday: Int {
        let components = DateComponents(year: displayedYear, month: displayedMonth, day: 1)
        let firstDate = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDate)
    }

    private var daysInMonth: Int {
        let components = DateComponents(year: displayedYear, month: displayedMonth)
        let date = calendar.date(from: components)!
        return calendar.range(of: .day, in: .month, for: date)!.count
    }

    private var todayDay: Int? {
        let now = Date.now
        if calendar.component(.year, from: now) == displayedYear,
           calendar.component(.month, from: now) == displayedMonth {
            return calendar.component(.day, from: now)
        }
        return nil
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.papamooMono(12, weight: .bold))
                        .foregroundStyle(day == "SUN" ? PapamooColor.sunday : PapamooColor.textMuted)
                        .tracking(0.6)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach((0..<(firstWeekday - 1)).map { "leading-\($0)" }, id: \.self) { _ in
                    Color.clear.frame(height: 60)
                }
                ForEach(1...daysInMonth, id: \.self) { day in
                    dayCell(for: day)
                }
            }
        }
        .padding(.horizontal, 14)
    }

    private func dayCell(for day: Int) -> some View {
        let columnIndex = (day + firstWeekday - 2) % 7
        let isSunday = columnIndex == 0
        let isSelected = selectedDay == day
        let total = dailyTotals[day]

        return Button {
            if selectedDay == day { selectedDay = nil } else { selectedDay = day }
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(PapamooColor.accent, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(PapamooColor.accent.opacity(0.06))
                        )
                }
                VStack(spacing: 3) {
                    Text("\(day)")
                        .font(.papamooMono(16, weight: .medium))
                        .foregroundStyle(isSunday ? PapamooColor.sunday : PapamooColor.text)
                    paymentAmount(total)
                }
                .padding(.horizontal, 2)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(day: day, total: total))
    }

    @ViewBuilder
    private func paymentAmount(_ total: Decimal?) -> some View {
        if let total {
            Text(CurrencyFormatter.amountString(total, currencyCode: currencyCode))
                .font(.papamooMono(10, weight: .bold))
                .foregroundStyle(PapamooColor.accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity)
        } else {
            Color.clear.frame(height: 12)
        }
    }

    private func accessibilityLabel(day: Int, total: Decimal?) -> String {
        guard let total else { return String(localized: "Day \(day)") }
        let amount = CurrencyFormatter.amountString(total, currencyCode: currencyCode)
        return String(localized: "Day \(day), \(amount) \(currencyCode) scheduled")
    }
}
