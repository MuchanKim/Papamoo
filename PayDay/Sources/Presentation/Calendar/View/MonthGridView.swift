import SwiftUI

struct MonthGridView: View {
    let year: Int
    let month: Int
    let eventDates: [Int: [SubscriptionCategory]]
    @Binding var selectedDay: Int?

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var firstWeekday: Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let date = Calendar.current.date(from: components)!
        return Calendar.current.component(.weekday, from: date) - 1
    }

    private var daysInMonth: Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        let date = Calendar.current.date(from: components)!
        return Calendar.current.range(of: .day, in: .month, for: date)!.count
    }

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays.indices, id: \.self) { index in
                    Text(weekdays[index])
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .frame(height: 24)
                }
            }
            .padding(.horizontal, 8)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(0..<(firstWeekday + daysInMonth), id: \.self) { index in
                    if index < firstWeekday {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    } else {
                        let day = index - firstWeekday + 1
                        dayCell(day: day)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func dayCell(day: Int) -> some View {
        let isSelected = selectedDay == day
        return VStack(spacing: 1) {
            Text("\(day)")
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .monospacedDigit()
                .frame(width: 30, height: 30)
                .background(isSelected ? PayDayColor.brand : .clear, in: Circle())
                .foregroundStyle(isSelected ? .white : .primary)

            if let categories = eventDates[day] {
                HStack(spacing: 2) {
                    ForEach(categories.indices, id: \.self) { _ in
                        Circle()
                            .fill(.secondary.opacity(0.45))
                            .frame(width: 5, height: 5)
                    }
                }
            } else {
                Color.clear.frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture { selectedDay = day }
    }
}
