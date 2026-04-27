import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline

struct SubscriptionEntry: TimelineEntry {
    let date: Date
    let subscriptions: [WidgetSub]
    let monthlyTotal: Decimal
    let totalCount: Int
    let baseCurrency: String
}

struct WidgetSub: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let amount: Decimal
    let currencyCode: String
    let nextPaymentDate: Date
    let daysUntil: Int
}

struct PayDayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SubscriptionEntry {
        SubscriptionEntry(
            date: .now,
            subscriptions: [
                WidgetSub(name: "Netflix", category: "streaming", amount: 17000, currencyCode: "KRW", nextPaymentDate: .now, daysUntil: 2),
                WidgetSub(name: "Claude", category: "ai", amount: 28000, currencyCode: "KRW", nextPaymentDate: .now, daysUntil: 5),
                WidgetSub(name: "Spotify", category: "streaming", amount: 10900, currencyCode: "KRW", nextPaymentDate: .now, daysUntil: 8),
                WidgetSub(name: "Notion", category: "productivity", amount: 12000, currencyCode: "KRW", nextPaymentDate: .now, daysUntil: 12),
            ],
            monthlyTotal: 95200,
            totalCount: 7,
            baseCurrency: "KRW"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SubscriptionEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubscriptionEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> SubscriptionEntry {
        do {
            let config = ModelConfiguration(
                groupContainer: .identifier("group.com.moolab.PayDay"),
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: Subscription.self, configurations: config)
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Subscription>()
            let subs = try context.fetch(descriptor)

            let widgetSubs = subs
                .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
                .prefix(4)
                .map { sub in
                    WidgetSub(
                        name: sub.name,
                        category: sub.category.rawValue,
                        amount: sub.amount,
                        currencyCode: sub.currencyCode,
                        nextPaymentDate: sub.nextPaymentDate,
                        daysUntil: sub.daysUntilNextPayment
                    )
                }

            let total = subs.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
            let baseCurrency = UserDefaults(suiteName: "group.com.moolab.PayDay")?.string(forKey: "baseCurrency") ?? "KRW"
            return SubscriptionEntry(date: .now, subscriptions: Array(widgetSubs), monthlyTotal: total, totalCount: subs.count, baseCurrency: baseCurrency)
        } catch {
            return SubscriptionEntry(date: .now, subscriptions: [], monthlyTotal: 0, totalCount: 0, baseCurrency: "KRW")
        }
    }
}

// MARK: - Widget Icon

private struct WidgetIcon: View {
    let category: String
    let size: CGFloat

    var body: some View {
        let systemName: String = switch category {
        case "streaming": "play.fill"
        case "ai": "sparkle"
        case "productivity": "doc.text.fill"
        default: "clock"
        }
        return RoundedRectangle(cornerRadius: size * 0.225)
            .fill(Color(.tertiarySystemFill))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.35, weight: .medium))
                    .foregroundStyle(.secondary)
            }
    }
}

private let brandColor = Color(red: 49/255, green: 130/255, blue: 246/255)

// MARK: - Small D-day Widget

struct SmallDdayWidget: Widget {
    let kind = "SmallDday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PayDayTimelineProvider()) { entry in
            SmallDdayView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Payment")
        .description("Shows your next upcoming payment.")
        .supportedFamilies([.systemSmall])
    }
}

private struct SmallDdayView: View {
    let entry: SubscriptionEntry

    var body: some View {
        if let next = entry.subscriptions.first {
            VStack(alignment: .leading) {
                HStack {
                    WidgetIcon(category: next.category, size: 28)
                    Spacer()
                    Text(next.nextPaymentDate, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("D-\(next.daysUntil)")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(brandColor)
                    .monospacedDigit()
                Text(next.amount, format: .currency(code: next.currencyCode).presentation(.narrow).precision(.fractionLength(0)))
                    .font(.headline)
                    .monospacedDigit()
                Text(next.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("No subscriptions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Small Total Widget

struct SmallTotalWidget: Widget {
    let kind = "SmallTotal"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PayDayTimelineProvider()) { entry in
            SmallTotalView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Monthly Total")
        .description("Shows your total monthly spending.")
        .supportedFamilies([.systemSmall])
    }
}

private struct SmallTotalView: View {
    let entry: SubscriptionEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.date, format: .dateTime.month(.wide))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
            Text(entry.monthlyTotal, format: .currency(code: entry.baseCurrency).presentation(.narrow).precision(.fractionLength(0)))
                .font(.system(size: 28, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("across \(entry.totalCount) services")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let next = entry.subscriptions.first {
                Text("\(next.nextPaymentDate, format: .dateTime.month(.abbreviated).day()) — \(next.name)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Medium Upcoming Widget

struct MediumUpcomingWidget: Widget {
    let kind = "MediumUpcoming"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PayDayTimelineProvider()) { entry in
            MediumUpcomingView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Upcoming Payments")
        .description("Shows your next 4 upcoming payments.")
        .supportedFamilies([.systemMedium])
    }
}

private struct MediumUpcomingView: View {
    let entry: SubscriptionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Upcoming")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                if let first = entry.subscriptions.first, let last = entry.subscriptions.last {
                    Text("\(first.nextPaymentDate, format: .dateTime.month(.abbreviated).day()) — \(last.nextPaymentDate, format: .dateTime.month(.abbreviated).day())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            ForEach(entry.subscriptions.prefix(4)) { sub in
                HStack(spacing: 8) {
                    WidgetIcon(category: sub.category, size: 22)
                    Text(sub.name)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    Text(sub.nextPaymentDate, format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 44, alignment: .trailing)
                    Text(sub.amount, format: .currency(code: sub.currencyCode).presentation(.narrow).precision(.fractionLength(0)))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .frame(minWidth: 64, alignment: .trailing)
                }
                .padding(.vertical, 2)
            }
        }
    }
}
