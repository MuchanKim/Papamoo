import SwiftUI

/// 결제일까지 남은 일수를 D-day 형식으로 표시하는 뱃지
struct DdayBadge: View {
    let days: Int

    private var isUrgent: Bool { days <= 3 }

    var body: some View {
        Text("D-\(days)")
            .font(.caption2)
            .fontWeight(.semibold)
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isUrgent ? PayDayColor.brandTint : Color(.quaternarySystemFill))
            .foregroundStyle(isUrgent ? PayDayColor.brand : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
