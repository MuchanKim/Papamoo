import SwiftUI

/// 카테고리 필터링에 사용되는 선택 가능한 칩 뷰
struct CategoryChip: View {
    let title: LocalizedStringResource
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isSelected ? Color(.label) : Color(.quaternarySystemFill))
            .foregroundStyle(isSelected ? Color(.systemBackground) : Color(.label))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
