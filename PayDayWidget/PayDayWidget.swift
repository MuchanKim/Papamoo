import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget tokens (mirror of app DesignTokens)

private enum WidgetColor {
    static let background = Color(red: 0.039, green: 0.039, blue: 0.039)
    static let text = Color.white
    static let muted = Color(red: 0.322, green: 0.322, blue: 0.322)
    static let accent = Color(red: 0.980, green: 0.800, blue: 0.082)
}

private extension Font {
    static func widgetMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let psName: String = switch weight {
        case .bold, .heavy, .black: "IBMPlexMono-Bold"
        case .semibold: "IBMPlexMono-SemiBold"
        case .medium: "IBMPlexMono-Medium"
        default: "IBMPlexMono-Regular"
        }
        return .custom(psName, size: size)
    }
}

// MARK: - Timeline

struct SubscriptionEntry: TimelineEntry {
    let date: Date
    let subscriptions: [WidgetSub]
    let monthlyTotal: Decimal
    let remainingThisMonth: Decimal
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
            remainingThisMonth: 68200,
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

            let groupDefaults = UserDefaults(suiteName: "group.com.moolab.PayDay")
            let baseCurrency = groupDefaults?.string(forKey: "baseCurrency") ?? "KRW"
            let rates = loadRates(from: groupDefaults)
            let total = subs.reduce(Decimal.zero) { acc, sub in
                acc + convertToBase(amount: sub.monthlyAmount, from: sub.currencyCode, to: baseCurrency, rates: rates)
            }
            // paidThisMonth: nextPaymentDate가 다음 달 이후 → 이번 달 결제 완료
            let calendar = Calendar.current
            let now = Date.now
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            let paid = subs
                .filter { sub in
                    let next = sub.nextPaymentDate
                    let nm = calendar.component(.month, from: next)
                    let ny = calendar.component(.year, from: next)
                    return ny > currentYear || (ny == currentYear && nm > currentMonth)
                }
                .reduce(Decimal.zero) { acc, sub in
                    acc + convertToBase(amount: sub.amount, from: sub.currencyCode, to: baseCurrency, rates: rates)
                }
            let remaining = total - paid
            return SubscriptionEntry(date: .now, subscriptions: Array(widgetSubs), monthlyTotal: total, remainingThisMonth: remaining, totalCount: subs.count, baseCurrency: baseCurrency)
        } catch {
            return SubscriptionEntry(date: .now, subscriptions: [], monthlyTotal: 0, remainingThisMonth: 0, totalCount: 0, baseCurrency: "KRW")
        }
    }

    private func loadRates(from defaults: UserDefaults?) -> [String: Double] {
        let fallback: [String: Double] = ["KRW": 1380, "JPY": 150]
        guard let data = defaults?.data(forKey: "exchangeRatesFromUSD"),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return fallback }
        return decoded
    }

    private func convertToBase(amount: Decimal, from code: String, to base: String, rates: [String: Double]) -> Decimal {
        guard code != base else { return amount }
        let krw: Decimal
        switch code {
        case "KRW": krw = amount
        case "USD": krw = amount * Decimal(rates["KRW"] ?? 1380)
        case "JPY":
            let krwRate = rates["KRW"] ?? 1380
            let jpyRate = rates["JPY"] ?? 150
            krw = amount * Decimal(krwRate / jpyRate)
        default: krw = amount
        }
        guard base != "KRW" else { return krw }
        let baseRate = rates[base] ?? 1
        let krwRate = rates["KRW"] ?? 1380
        return krw * Decimal(baseRate / krwRate)
    }
}

// MARK: - Helpers

private func amountString(_ value: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter.string(for: value) ?? "0"
}

// MARK: - Small D-day Widget

struct SmallDdayWidget: Widget {
    let kind = "SmallDday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PayDayTimelineProvider()) { entry in
            SmallDdayView(entry: entry)
                .containerBackground(WidgetColor.background, for: .widget)
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
            VStack(alignment: .leading, spacing: 0) {
                Text("PAYDAY")
                    .font(.widgetMono(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(WidgetColor.muted)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("D-")
                        .font(.widgetMono(28, weight: .bold))
                        .foregroundStyle(WidgetColor.accent)
                    Text("\(next.daysUntil)")
                        .font(.widgetMono(28, weight: .bold))
                        .foregroundStyle(WidgetColor.text)
                        .monospacedDigit()
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(amountString(next.amount))
                        .font(.widgetMono(13, weight: .bold))
                        .foregroundStyle(WidgetColor.text)
                        .monospacedDigit()
                    Text(next.currencyCode)
                        .font(.widgetMono(9, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(WidgetColor.accent)
                }
                .padding(.top, 2)
                Text(next.name.uppercased())
                    .font(.widgetMono(9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(WidgetColor.muted)
                    .padding(.top, 1)
                Rectangle()
                    .fill(WidgetColor.accent)
                    .frame(height: 2)
                    .padding(.top, 6)
            }
        } else {
            VStack(alignment: .leading) {
                Text("NO SUBSCRIPTIONS")
                    .font(.widgetMono(9, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(WidgetColor.muted)
            }
        }
    }
}

// MARK: - Small Total Widget

struct SmallTotalWidget: Widget {
    let kind = "SmallTotal"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PayDayTimelineProvider()) { entry in
            SmallTotalView(entry: entry)
                .containerBackground(WidgetColor.background, for: .widget)
        }
        .configurationDisplayName("Monthly Total")
        .description("Shows your total monthly spending.")
        .supportedFamilies([.systemSmall])
    }
}

private struct SmallTotalView: View {
    let entry: SubscriptionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(monthName(entry.date)) · \(String(localized: "remaining"))")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WidgetColor.muted)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(amountString(entry.remainingThisMonth))
                    .font(.widgetMono(28, weight: .bold))
                    .foregroundStyle(WidgetColor.text)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(entry.baseCurrency)
                    .font(.widgetMono(11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(WidgetColor.accent)
            }
            .padding(.top, 2)
            Text("\(entry.totalCount) subscriptions")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WidgetColor.muted)
                .padding(.top, 4)
            Rectangle()
                .fill(WidgetColor.muted.opacity(0.3))
                .frame(height: 1)
                .padding(.vertical, 8)
            if let next = entry.subscriptions.first {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Next")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(WidgetColor.muted)
                        .textCase(.uppercase)
                    Text(next.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetColor.text)
                        .lineLimit(1)
                    HStack(alignment: .firstTextBaseline) {
                        HStack(spacing: 3) {
                            Text(amountString(next.amount))
                                .foregroundStyle(WidgetColor.text)
                                .monospacedDigit()
                                .font(.widgetMono(11, weight: .semibold))
                            Text(next.currencyCode)
                                .font(.widgetMono(8, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(WidgetColor.accent)
                        }
                        Spacer()
                        Text("D-\(next.daysUntil)")
                            .font(.widgetMono(11, weight: .bold))
                            .foregroundStyle(WidgetColor.accent)
                    }
                    .padding(.top, 1)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func monthName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}

// MARK: - Medium Upcoming Widget

struct MediumUpcomingWidget: Widget {
    let kind = "MediumUpcoming"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PayDayTimelineProvider()) { entry in
            MediumUpcomingView(entry: entry)
                .containerBackground(WidgetColor.background, for: .widget)
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
                Text("UPCOMING")
                    .font(.widgetMono(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(WidgetColor.muted)
                Spacer()
                Text("PAYDAY")
                    .font(.widgetMono(9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(WidgetColor.muted)
            }
            Rectangle()
                .fill(WidgetColor.accent)
                .frame(height: 2)
                .padding(.top, 6)
                .padding(.bottom, 6)
            ForEach(entry.subscriptions.prefix(4)) { sub in
                HStack(alignment: .firstTextBaseline) {
                    Text(sub.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetColor.text)
                        .lineLimit(1)
                    Spacer()
                    Text(formattedDate(sub.nextPaymentDate))
                        .font(.widgetMono(9, weight: .regular))
                        .foregroundStyle(WidgetColor.muted)
                        .tracking(0.4)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(amountString(sub.amount))
                            .font(.widgetMono(11, weight: .bold))
                            .foregroundStyle(WidgetColor.text)
                            .monospacedDigit()
                        Text(sub.currencyCode)
                            .font(.widgetMono(8, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(WidgetColor.accent)
                    }
                    .frame(minWidth: 70, alignment: .trailing)
                }
                .padding(.vertical, 2)
            }
            Spacer(minLength: 0)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }
}
