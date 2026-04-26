import SwiftUI

/// 섹션 타이틀을 표시하는 공통 헤더.
struct SectionHeaderView: View {
    let title: LocalizedStringResource

    var body: some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}
