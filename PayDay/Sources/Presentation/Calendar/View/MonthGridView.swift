import SwiftUI

struct MonthGridView: View {
    let displayedMonth: Int
    let displayedYear: Int
    let eventDates: [Int: [SubscriptionCategory]]
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
                        .font(.payDayMono(10, weight: .bold))
                        .foregroundStyle(day == "SUN" ? PayDayColor.sunday : PayDayColor.textMuted)
                        .tracking(0.6)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                    Color.clear.frame(height: 38)
                }
                ForEach(1...daysInMonth, id: \.self) { day in
                    dayCell(for: day)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func dayCell(for day: Int) -> some View {
        let columnIndex = (day + firstWeekday - 2) % 7
        let isSunday = columnIndex == 0
        let isToday = todayDay == day
        let isSelected = selectedDay == day
        let payments = eventDates[day] ?? []

        return Button {
            if selectedDay == day { selectedDay = nil } else { selectedDay = day }
        } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(PayDayColor.accent, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(PayDayColor.accent.opacity(0.06))
                        )
                }
                VStack(spacing: 2) {
                    Text(String(format: "%02d", day))
                        .font(.payDayMono(13, weight: isToday ? .bold : .medium))
                        .foregroundStyle(dayColor(isToday: isToday, isSunday: isSunday))
                    paymentMarker(count: payments.count)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 38)
        }
        .buttonStyle(.plain)
    }

    private func dayColor(isToday: Bool, isSunday: Bool) -> Color {
        if isToday { return PayDayColor.accent }
        if isSunday { return PayDayColor.sunday }
        return PayDayColor.text
    }

    @ViewBuilder
    private func paymentMarker(count: Int) -> some View {
        switch count {
        case 0:
            Color.clear.frame(height: 4)
        case 1:
            Circle()
                .fill(PayDayColor.accent)
                .frame(width: 4, height: 4)
        default:
            Rectangle()
                .fill(PayDayColor.accent)
                .frame(width: 16, height: 2)
        }
    }
}
