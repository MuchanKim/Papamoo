import SwiftUI

struct HeroSummaryCard: View {
    let remainingAmount: Decimal
    let paidAmount: Decimal
    let totalAmount: Decimal
    var currencyCode: String = "KRW"

    private var isAllPaid: Bool { remainingAmount <= 0 }

    var body: some View {
        ZStack {
            cardBackground
            if isAllPaid {
                allPaidContent
            } else {
                remainingContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 4)
    }

    // MARK: - Background

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.15, blue: 0.27),
                    Color(red: 0.10, green: 0.23, blue: 0.42),
                    Color(red: 0.12, green: 0.27, blue: 0.50)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                let step: CGFloat = 8
                for i in stride(from: 0, to: size.width + size.height, by: step) {
                    var path = Path()
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: i))
                    context.stroke(path, with: .color(.white.opacity(0.025)), lineWidth: 0.5)
                }
            }
        }
    }

    // MARK: - Remaining Content

    private var remainingContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Remaining this month")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.50))
                .textCase(.uppercase)
                .tracking(0.5)

            Text(remainingAmount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.top, 8)

            paidTotalLine
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .padding(.horizontal, 4)
    }

    private var paidTotalLine: some View {
        HStack(spacing: 0) {
            Text(paidAmount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .foregroundStyle(.white.opacity(0.50))
            Text(" \(String(localized: "paid"))")
                .foregroundStyle(.white.opacity(0.50))

            Text(" \u{00B7} ")
                .foregroundStyle(.white.opacity(0.20))

            Text(totalAmount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .foregroundStyle(.white.opacity(0.50))
            Text(" \(String(localized: "total"))")
                .foregroundStyle(.white.opacity(0.50))
        }
        .font(.system(size: 13))
        .monospacedDigit()
    }

    // MARK: - All Paid Content

    private var allPaidContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.80))

                Text("All paid this month")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.80))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            Text(totalAmount, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.top, 8)

            Text("Next billing in \(daysUntilNextMonth) days")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.50))
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .padding(.horizontal, 4)
    }

    private var daysUntilNextMonth: Int {
        let calendar = Calendar.current
        let now = Date.now
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.startOfDay(for: now)),
              let firstOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))
        else { return 0 }
        return calendar.dateComponents([.day], from: now, to: firstOfNextMonth).day ?? 0
    }
}
