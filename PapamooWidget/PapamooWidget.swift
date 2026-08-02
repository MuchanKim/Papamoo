import OSLog
import WidgetKit
import SwiftUI

struct SubscriptionEntry: TimelineEntry {
    let date: Date
    let subscriptions: [WidgetSub]
    let monthlyTotal: Decimal
    let remainingThisMonth: Decimal
    let totalCount: Int
    let baseCurrency: String
    let availability: WidgetDataAvailability
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

struct PapamooTimelineProvider: TimelineProvider {

    // MARK: - Methods

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
            remainingThisMonth: 68200,
            totalCount: 7,
            baseCurrency: "KRW",
            availability: .available
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SubscriptionEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubscriptionEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Private Methods

    private func loadEntry() -> SubscriptionEntry {
        let logger = Logger(subsystem: "com.moolab.Papamoo", category: "WidgetSnapshot")
        do {
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppGroup.identifier
            ) else {
                logger.error("App Group container is unavailable")
                return unavailableEntry()
            }
            guard let snapshot = try WidgetSnapshotStore(containerURL: containerURL).load() else {
                logger.error("Widget snapshot has not been created")
                return unavailableEntry()
            }

            let subscriptions = snapshot.subscriptions.map {
                WidgetSub(
                    name: $0.name,
                    category: $0.category,
                    amount: $0.amount,
                    currencyCode: $0.currencyCode,
                    nextPaymentDate: $0.nextPaymentDate,
                    daysUntil: $0.daysUntil
                )
            }
            return SubscriptionEntry(
                date: snapshot.generatedAt,
                subscriptions: subscriptions,
                monthlyTotal: snapshot.monthlyTotal,
                remainingThisMonth: snapshot.remainingThisMonth,
                totalCount: snapshot.totalCount,
                baseCurrency: snapshot.baseCurrency,
                availability: .available
            )
        } catch {
            logger.error("Unable to load widget snapshot: \(error.localizedDescription, privacy: .public)")
            return unavailableEntry()
        }
    }

    private func unavailableEntry() -> SubscriptionEntry {
        SubscriptionEntry(
            date: .now,
            subscriptions: [],
            monthlyTotal: 0,
            remainingThisMonth: 0,
            totalCount: 0,
            baseCurrency: "",
            availability: .unavailable
        )
    }
}

private func amountString(_ value: Decimal, currencyCode: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = switch currencyCode {
    case "KRW", "JPY": 0
    default: 2
    }
    guard let result = formatter.string(from: NSDecimalNumber(decimal: value)) else {
        preconditionFailure("Unable to format amount for currency \(currencyCode)")
    }
    return result
}

private struct WidgetUnavailableView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(PapamooColor.accent)
            Text("DATA UNAVAILABLE")
                .font(.papamooMono(9, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(PapamooColor.text)
            Text("OPEN PAPAMOO")
                .font(.papamooMono(8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(PapamooColor.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct SmallDdayWidget: Widget {

    let kind = "SmallDday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PapamooTimelineProvider()) { entry in
            SmallDdayView(entry: entry)
                .containerBackground(PapamooColor.background, for: .widget)
        }
        .configurationDisplayName("Next Payment")
        .description("Shows your next upcoming payment.")
        .supportedFamilies([.systemSmall])
    }
}

private struct SmallDdayView: View {

    let entry: SubscriptionEntry

    var body: some View {
        if entry.availability == .unavailable {
            WidgetUnavailableView()
        } else if let next = entry.subscriptions.first {
            VStack(alignment: .leading, spacing: 0) {
                Text("PAYDAY")
                    .font(.papamooMono(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(PapamooColor.textMuted)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("D-")
                        .font(.papamooMono(28, weight: .bold))
                        .foregroundStyle(PapamooColor.accent)
                    Text("\(next.daysUntil)")
                        .font(.papamooMono(28, weight: .bold))
                        .foregroundStyle(PapamooColor.text)
                        .monospacedDigit()
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(amountString(next.amount, currencyCode: next.currencyCode))
                        .font(.papamooMono(13, weight: .bold))
                        .foregroundStyle(PapamooColor.text)
                        .monospacedDigit()
                    Text(next.currencyCode)
                        .font(.papamooMono(9, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(PapamooColor.accent)
                }
                .padding(.top, 2)
                Text(next.name.uppercased())
                    .font(.papamooMono(9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(PapamooColor.textMuted)
                    .padding(.top, 1)
                Rectangle()
                    .fill(PapamooColor.accent)
                    .frame(height: 2)
                    .padding(.top, 6)
            }
        } else {
            VStack(alignment: .leading) {
                Text("NO SUBSCRIPTIONS")
                    .font(.papamooMono(9, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(PapamooColor.textMuted)
            }
        }
    }
}

struct SmallTotalWidget: Widget {

    let kind = "SmallTotal"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PapamooTimelineProvider()) { entry in
            SmallTotalView(entry: entry)
                .containerBackground(PapamooColor.background, for: .widget)
        }
        .configurationDisplayName("Monthly Total")
        .description("Shows your total monthly spending.")
        .supportedFamilies([.systemSmall])
    }
}

private struct SmallTotalView: View {

    // MARK: - Properties

    let entry: SubscriptionEntry

    var body: some View {
        if entry.availability == .unavailable {
            WidgetUnavailableView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(monthName(entry.date)) · \(String(localized: "remaining"))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(PapamooColor.textMuted)
                    .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(amountString(entry.remainingThisMonth, currencyCode: entry.baseCurrency))
                        .font(.papamooMono(28, weight: .bold))
                        .foregroundStyle(PapamooColor.text)
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(entry.baseCurrency)
                        .font(.papamooMono(11, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(PapamooColor.accent)
                }
                .padding(.top, 2)
                Text("\(entry.totalCount) subscriptions")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(PapamooColor.textMuted)
                    .padding(.top, 4)
                Rectangle()
                    .fill(PapamooColor.textMuted.opacity(0.3))
                    .frame(height: 1)
                    .padding(.vertical, 8)
                if let next = entry.subscriptions.first {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Next")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(PapamooColor.textMuted)
                            .textCase(.uppercase)
                        Text(next.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(PapamooColor.text)
                            .lineLimit(1)
                        HStack(alignment: .firstTextBaseline) {
                            HStack(spacing: 3) {
                                Text(amountString(next.amount, currencyCode: next.currencyCode))
                                    .foregroundStyle(PapamooColor.text)
                                    .monospacedDigit()
                                    .font(.papamooMono(11, weight: .semibold))
                                Text(next.currencyCode)
                                    .font(.papamooMono(8, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundStyle(PapamooColor.accent)
                            }
                            Spacer()
                            Text("D-\(next.daysUntil)")
                                .font(.papamooMono(11, weight: .bold))
                                .foregroundStyle(PapamooColor.accent)
                        }
                        .padding(.top, 1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Private Methods

    private func monthName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}

struct MediumUpcomingWidget: Widget {

    let kind = "MediumUpcoming"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PapamooTimelineProvider()) { entry in
            MediumUpcomingView(entry: entry)
                .containerBackground(PapamooColor.background, for: .widget)
        }
        .configurationDisplayName("Upcoming Payments")
        .description("Shows your next 4 upcoming payments.")
        .supportedFamilies([.systemMedium])
    }
}

private struct MediumUpcomingView: View {

    // MARK: - Properties

    let entry: SubscriptionEntry

    var body: some View {
        if entry.availability == .unavailable {
            WidgetUnavailableView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("UPCOMING")
                        .font(.papamooMono(9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(PapamooColor.textMuted)
                    Spacer()
                    Text("PAYDAY")
                        .font(.papamooMono(9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(PapamooColor.textMuted)
                }
                Rectangle()
                    .fill(PapamooColor.accent)
                    .frame(height: 2)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                ForEach(entry.subscriptions.prefix(4)) { sub in
                    HStack(alignment: .firstTextBaseline) {
                        Text(sub.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(PapamooColor.text)
                            .lineLimit(1)
                        Spacer()
                        Text(formattedDate(sub.nextPaymentDate))
                            .font(.papamooMono(9, weight: .regular))
                            .foregroundStyle(PapamooColor.textMuted)
                            .tracking(0.4)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(amountString(sub.amount, currencyCode: sub.currencyCode))
                                .font(.papamooMono(11, weight: .bold))
                                .foregroundStyle(PapamooColor.text)
                                .monospacedDigit()
                            Text(sub.currencyCode)
                                .font(.papamooMono(8, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(PapamooColor.accent)
                        }
                        .frame(minWidth: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Private Methods

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }
}
