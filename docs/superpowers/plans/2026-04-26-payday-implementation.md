# PayDay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iOS 구독 관리 앱 — 구독 서비스를 수동 등록하고, 캘린더에서 결제일을 확인하며, 결제 전 알림을 받는 앱. WidgetKit 위젯 3종 포함.

**Architecture:** SwiftData로 로컬 데이터 저장 + iCloud 자동 동기화. TabView 3탭 (Home/Calendar/Settings) 구조. UserNotifications로 D-1/D-3 결제 알림. WidgetKit Extension으로 Small 2종 + Medium 1종 위젯. iOS 26.4+, Swift 6.0, Light mode only.

**Tech Stack:** SwiftUI, SwiftData, WidgetKit, UserNotifications, Swift Testing

**Design Reference:** `/tmp/payday/` 핸드오프 번들. `hifi-tokens.jsx`에 디자인 토큰, `hifi-screens.jsx`에 전체 화면 정의.

---

## File Structure

```
PayDay/PayDay/
├── PayDayApp.swift                    ← App 진입점 (ModelContainer + 알림 설정)
├── ContentView.swift                  ← TabView 루트
│
├── Models/
│   ├── Subscription.swift             ← SwiftData @Model
│   ├── BillingCycle.swift             ← enum: monthly, yearly
│   ├── SubscriptionCategory.swift     ← enum: streaming, ai, productivity, other
│   └── PresetService.swift            ← 프리셋 서비스 정의 (static data)
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift             ← 홈 탭 전체
│   │   ├── HeroSummaryCard.swift      ← 월간 총액 hero 카드
│   │   └── SubscriptionRow.swift      ← 구독 리스트 행
│   │
│   ├── Calendar/
│   │   ├── CalendarView.swift         ← 캘린더 탭 전체
│   │   ├── MonthGridView.swift        ← 월간 그리드 + dot 이벤트
│   │   └── MonthlyTotalBar.swift      ← 하단 sticky 월간 총액
│   │
│   ├── Settings/
│   │   └── SettingsView.swift         ← 설정 탭 전체
│   │
│   ├── AddSubscription/
│   │   ├── AddSubscriptionSearchView.swift  ← 서비스 검색/선택 시트
│   │   └── AddSubscriptionDetailView.swift  ← 구독 상세 입력 시트
│   │
│   └── Components/
│       ├── ServiceIconView.swift      ← 카테고리별 아이콘 (rounded rect + glyph)
│       ├── DdayBadge.swift            ← D-day 뱃지
│       └── CategoryChip.swift         ← 카테고리 필터 chip
│
├── Services/
│   └── NotificationManager.swift      ← UserNotifications 스케줄링
│
└── Utilities/
    └── DesignTokens.swift             ← 컬러/폰트/간격 상수

PayDay/PayDayWidgets/                  ← WidgetKit Extension (신규 타겟)
├── PayDayWidgets.swift                ← Widget 번들 정의
├── WidgetTimelineProvider.swift       ← Timeline provider
├── SmallDdayWidget.swift              ← Small D-day 위젯
├── SmallTotalWidget.swift             ← Small Total 위젯
└── MediumUpcomingWidget.swift         ← Medium Upcoming 위젯

PayDay/PayDayTests/
└── PayDayTests.swift                  ← 모델/비즈니스 로직 테스트
```

---

## Task 1: SwiftData 모델 및 기본 타입 정의

**Files:**
- Create: `PayDay/Models/BillingCycle.swift`
- Create: `PayDay/Models/SubscriptionCategory.swift`
- Create: `PayDay/Models/Subscription.swift`
- Create: `PayDay/Models/PresetService.swift`
- Test: `PayDayTests/PayDayTests.swift`

- [ ] **Step 1: BillingCycle enum 작성**

```swift
// BillingCycle.swift
import Foundation

enum BillingCycle: String, Codable, CaseIterable {
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    var monthMultiplier: Int {
        switch self {
        case .monthly: 1
        case .yearly: 12
        }
    }
}
```

- [ ] **Step 2: SubscriptionCategory enum 작성**

```swift
// SubscriptionCategory.swift
import SwiftUI

enum SubscriptionCategory: String, Codable, CaseIterable {
    case streaming
    case ai
    case productivity
    case other

    var displayName: String {
        switch self {
        case .streaming: "Streaming"
        case .ai: "AI"
        case .productivity: "Productivity"
        case .other: "Other"
        }
    }

    var iconSystemName: String {
        switch self {
        case .streaming: "play.fill"
        case .ai: "sparkle"
        case .productivity: "doc.text.fill"
        case .other: "clock"
        }
    }

    var iconTintColor: Color {
        switch self {
        case .streaming: Color(red: 142/255, green: 142/255, blue: 147/255)
        case .ai: Color(red: 99/255, green: 99/255, blue: 102/255)
        case .productivity: Color(red: 174/255, green: 174/255, blue: 178/255)
        case .other: Color(red: 199/255, green: 199/255, blue: 204/255)
        }
    }
}
```

- [ ] **Step 3: Subscription SwiftData 모델 작성**

```swift
// Subscription.swift
import Foundation
import SwiftData

@Model
final class Subscription {
    var name: String
    var amount: Decimal
    var billingCycle: BillingCycle
    var firstPaymentDate: Date
    var category: SubscriptionCategory
    var note: String
    var isRemindOneDayBefore: Bool
    var isRemindThreeDaysBefore: Bool

    init(
        name: String,
        amount: Decimal,
        billingCycle: BillingCycle = .monthly,
        firstPaymentDate: Date,
        category: SubscriptionCategory = .other,
        note: String = "",
        isRemindOneDayBefore: Bool = true,
        isRemindThreeDaysBefore: Bool = false
    ) {
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.firstPaymentDate = firstPaymentDate
        self.category = category
        self.note = note
        self.isRemindOneDayBefore = isRemindOneDayBefore
        self.isRemindThreeDaysBefore = isRemindThreeDaysBefore
    }

    /// The next payment date from today.
    var nextPaymentDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.startOfDay(for: firstPaymentDate)

        guard start <= today else { return start }

        let component: Calendar.Component = billingCycle == .monthly ? .month : .year
        var candidate = start
        while candidate <= today {
            guard let next = calendar.date(byAdding: component, value: 1, to: candidate) else {
                return candidate
            }
            candidate = next
        }
        return candidate
    }

    /// Days until next payment from today.
    var daysUntilNextPayment: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let next = calendar.startOfDay(for: nextPaymentDate)
        return calendar.dateComponents([.day], from: today, to: next).day ?? 0
    }

    /// Monthly equivalent amount for consistent comparison.
    var monthlyAmount: Decimal {
        switch billingCycle {
        case .monthly: amount
        case .yearly: amount / 12
        }
    }
}
```

- [ ] **Step 4: PresetService 작성**

```swift
// PresetService.swift
import Foundation

struct PresetService: Identifiable {
    let id = UUID()
    let name: String
    let category: SubscriptionCategory
    let defaultAmount: Decimal

    static let all: [PresetService] = [
        // Streaming
        PresetService(name: "Netflix", category: .streaming, defaultAmount: 17000),
        PresetService(name: "YouTube Premium", category: .streaming, defaultAmount: 14900),
        PresetService(name: "Apple Music", category: .streaming, defaultAmount: 10900),
        PresetService(name: "Spotify", category: .streaming, defaultAmount: 10900),
        PresetService(name: "Disney+", category: .streaming, defaultAmount: 9900),
        PresetService(name: "Apple TV+", category: .streaming, defaultAmount: 9900),
        PresetService(name: "Watcha", category: .streaming, defaultAmount: 7900),
        // AI
        PresetService(name: "Claude", category: .ai, defaultAmount: 28000),
        PresetService(name: "ChatGPT Plus", category: .ai, defaultAmount: 28000),
        PresetService(name: "Gemini Advanced", category: .ai, defaultAmount: 28000),
        PresetService(name: "Midjourney", category: .ai, defaultAmount: 13000),
        PresetService(name: "Cursor", category: .ai, defaultAmount: 28000),
        // Productivity
        PresetService(name: "Notion", category: .productivity, defaultAmount: 12000),
        PresetService(name: "Figma", category: .productivity, defaultAmount: 20000),
        PresetService(name: "GitHub Pro", category: .productivity, defaultAmount: 4000),
        PresetService(name: "1Password", category: .productivity, defaultAmount: 4500),
        PresetService(name: "iCloud+", category: .productivity, defaultAmount: 1100),
        PresetService(name: "Google One", category: .productivity, defaultAmount: 2400),
    ]
}
```

- [ ] **Step 5: Subscription 모델 테스트 작성**

```swift
// PayDayTests.swift
import Testing
import Foundation
@testable import PayDay

struct SubscriptionTests {

    @Test func nextPaymentDateFutureStart() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: .now)!
        let sub = Subscription(name: "Test", amount: 10000, firstPaymentDate: futureDate)
        let expected = Calendar.current.startOfDay(for: futureDate)
        #expect(Calendar.current.startOfDay(for: sub.nextPaymentDate) == expected)
    }

    @Test func nextPaymentDatePastStart() {
        let pastDate = Calendar.current.date(byAdding: .month, value: -3, to: .now)!
        let sub = Subscription(name: "Test", amount: 10000, firstPaymentDate: pastDate)
        #expect(sub.nextPaymentDate > .now || Calendar.current.isDateInToday(sub.nextPaymentDate))
    }

    @Test func daysUntilNextPayment() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: .now)!
        let sub = Subscription(name: "Test", amount: 10000, firstPaymentDate: futureDate)
        #expect(sub.daysUntilNextPayment == 5)
    }

    @Test func monthlyAmountForYearly() {
        let sub = Subscription(
            name: "Test", amount: 120000,
            billingCycle: .yearly,
            firstPaymentDate: .now
        )
        #expect(sub.monthlyAmount == 10000)
    }

    @Test func presetServicesNotEmpty() {
        #expect(!PresetService.all.isEmpty)
    }

    @Test func presetServicesHaveAllCategories() {
        let categories = Set(PresetService.all.map(\.category))
        #expect(categories.contains(.streaming))
        #expect(categories.contains(.ai))
        #expect(categories.contains(.productivity))
    }
}
```

- [ ] **Step 6: 테스트 실행**

Run: `cd /Users/muchankim/Dev/PayDay/PayDay && xcodebuild test -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 7: 커밋**

```bash
git add Models/ PayDayTests/
git commit -m "[Feat] - SwiftData 모델 및 기본 타입 정의

What?
- Subscription @Model, BillingCycle, SubscriptionCategory enum 구현
- PresetService 프리셋 서비스 데이터 정의 (18개 서비스)
- nextPaymentDate, daysUntilNextPayment 비즈니스 로직 포함
- 모델 로직 유닛 테스트 작성"
```

---

## Task 2: 디자인 토큰 및 공통 컴포넌트

**Files:**
- Create: `PayDay/Utilities/DesignTokens.swift`
- Create: `PayDay/Views/Components/ServiceIconView.swift`
- Create: `PayDay/Views/Components/DdayBadge.swift`
- Create: `PayDay/Views/Components/CategoryChip.swift`

- [ ] **Step 1: DesignTokens 작성**

```swift
// DesignTokens.swift
import SwiftUI

enum PayDayColor {
    static let brand = Color(red: 49/255, green: 130/255, blue: 246/255)
    static let brandPressed = Color(red: 27/255, green: 100/255, blue: 218/255)
    static let brandTint = Color(red: 49/255, green: 130/255, blue: 246/255).opacity(0.12)
}
```

- [ ] **Step 2: ServiceIconView 작성**

```swift
// ServiceIconView.swift
import SwiftUI

struct ServiceIconView: View {
    let category: SubscriptionCategory
    var size: CGFloat = 40

    private var cornerRadius: CGFloat {
        size * 0.225
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.tertiarySystemFill))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: category.iconSystemName)
                    .font(.system(size: size * 0.35, weight: .medium))
                    .foregroundStyle(.secondary)
            }
    }
}
```

- [ ] **Step 3: DdayBadge 작성**

```swift
// DdayBadge.swift
import SwiftUI

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
```

- [ ] **Step 4: CategoryChip 작성**

```swift
// CategoryChip.swift
import SwiftUI

struct CategoryChip: View {
    let title: String
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
```

- [ ] **Step 5: 빌드 확인**

Run: `cd /Users/muchankim/Dev/PayDay/PayDay && xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: 커밋**

```bash
git add Utilities/ Views/Components/
git commit -m "[Feat] - 디자인 토큰 및 공통 컴포넌트 구현

What?
- PayDayColor 디자인 토큰 (Toss-style brand blue)
- ServiceIconView, DdayBadge, CategoryChip 공통 컴포넌트"
```

---

## Task 3: App 진입점 + TabView 루트

**Files:**
- Modify: `PayDay/PayDayApp.swift`
- Modify: `PayDay/ContentView.swift`

- [ ] **Step 1: PayDayApp에 ModelContainer 설정**

```swift
// PayDayApp.swift
import SwiftUI
import SwiftData

@main
struct PayDayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Subscription.self)
    }
}
```

- [ ] **Step 2: ContentView를 TabView로 교체**

```swift
// ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("My Subs", systemImage: "creditcard.fill") {
                HomeView()
            }
            Tab("Calendar", systemImage: "calendar") {
                CalendarView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(PayDayColor.brand)
    }
}
```

- [ ] **Step 3: 빈 탭 뷰 스텁 생성**

HomeView, CalendarView, SettingsView를 NavigationStack + "Coming soon" Text로 스텁 생성:

```swift
// HomeView.swift
import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text("Home")
                .navigationTitle("My Subs")
        }
    }
}

// CalendarView.swift
import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            Text("Calendar")
                .navigationTitle("Calendar")
        }
    }
}

// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings")
                .navigationTitle("Settings")
        }
    }
}
```

- [ ] **Step 4: 빌드 확인**

Run: `xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 커밋**

```bash
git add PayDayApp.swift ContentView.swift Views/
git commit -m "[Feat] - App 진입점 및 TabView 루트 구성

What?
- SwiftData ModelContainer 설정
- TabView 3탭 (My Subs / Calendar / Settings)
- 각 탭 스텁 뷰 생성"
```

---

## Task 4: Home 탭 구현

**Files:**
- Modify: `PayDay/Views/Home/HomeView.swift`
- Create: `PayDay/Views/Home/HeroSummaryCard.swift`
- Create: `PayDay/Views/Home/SubscriptionRow.swift`

- [ ] **Step 1: HeroSummaryCard 작성**

```swift
// HeroSummaryCard.swift
import SwiftUI

struct HeroSummaryCard: View {
    let totalAmount: Decimal
    let subscriptionCount: Int
    let nextPaymentDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This month")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(totalAmount, format: .currency(code: "KRW").precision(.fractionLength(0)))
                .font(.system(size: 44, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            HStack(spacing: 0) {
                Text("\(subscriptionCount) subscriptions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let nextPaymentDate {
                    Text(" · next on ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(nextPaymentDate, format: .dateTime.month(.abbreviated).day())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(PayDayColor.brand)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
```

- [ ] **Step 2: SubscriptionRow 작성**

```swift
// SubscriptionRow.swift
import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription
    var showDday: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ServiceIconView(category: subscription.category)

            VStack(alignment: .leading, spacing: 1) {
                Text(subscription.name)
                    .font(.body)
                Text(subscription.nextPaymentDate, format: .dateTime.month(.abbreviated).day())
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            HStack(spacing: 6) {
                Text(subscription.amount, format: .currency(code: "KRW").precision(.fractionLength(0)))
                    .font(.body)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(showDday ? PayDayColor.brand : .primary)

                if showDday {
                    DdayBadge(days: subscription.daysUntilNextPayment)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.quaternary)
        }
    }
}
```

- [ ] **Step 3: HomeView 전체 구현**

```swift
// HomeView.swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Subscription.firstPaymentDate) private var subscriptions: [Subscription]
    @State private var isShowingAddSheet = false

    private var sortedByNextPayment: [Subscription] {
        subscriptions.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
    }

    private var thisMonthTotal: Decimal {
        subscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    private var nextPayment: Subscription? {
        sortedByNextPayment.first
    }

    private var thisWeekSubscriptions: [Subscription] {
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: .now)!
        return sortedByNextPayment.filter { $0.nextPaymentDate <= endOfWeek }
    }

    private var nextWeekSubscriptions: [Subscription] {
        let calendar = Calendar.current
        let endOfThisWeek = calendar.date(byAdding: .day, value: 7, to: .now)!
        let endOfNextWeek = calendar.date(byAdding: .day, value: 14, to: .now)!
        return sortedByNextPayment.filter {
            $0.nextPaymentDate > endOfThisWeek && $0.nextPaymentDate <= endOfNextWeek
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    nextPaymentSection
                    weekSection(title: "This week", subscriptions: thisWeekSubscriptions)
                    weekSection(title: "Next week", subscriptions: nextWeekSubscriptions)
                }
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Subs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isShowingAddSheet = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(PayDayColor.brand)
                            .frame(width: 36, height: 36)
                            .background(PayDayColor.brandTint, in: Circle())
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddSubscriptionSearchView()
            }
        }
    }

    private var heroSection: some View {
        HeroSummaryCard(
            totalAmount: thisMonthTotal,
            subscriptionCount: subscriptions.count,
            nextPaymentDate: nextPayment?.nextPaymentDate
        )
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var nextPaymentSection: some View {
        if let nextPayment {
            Section {
                SubscriptionRow(subscription: nextPayment, showDday: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
            } header: {
                sectionHeader(title: "Next payment")
            }
        }
    }

    private func weekSection(title: String, subscriptions: [Subscription]) -> some View {
        Group {
            if !subscriptions.isEmpty {
                Section {
                    VStack(spacing: 0) {
                        ForEach(Array(subscriptions.enumerated()), id: \.element.persistentModelID) { index, sub in
                            SubscriptionRow(subscription: sub)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                            if index < subscriptions.count - 1 {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                } header: {
                    let total = subscriptions.reduce(Decimal.zero) { $0 + $1.amount }
                    HStack {
                        sectionHeader(title: title)
                        Spacer()
                        Text(total, format: .currency(code: "KRW").precision(.fractionLength(0)))
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.tertiary)
            .padding(.leading, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}
```

- [ ] **Step 4: 빌드 확인**

Run: `xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 커밋**

```bash
git add Views/Home/
git commit -m "[Feat] - Home 탭 구현

What?
- HeroSummaryCard (월간 총액 + 구독 수 + 다음 결제일)
- SubscriptionRow (아이콘 + 이름 + 날짜 + 금액 + D-day 뱃지)
- This week / Next week 그룹 리스트
- Next payment 강조 섹션"
```

---

## Task 5: Calendar 탭 구현

**Files:**
- Modify: `PayDay/Views/Calendar/CalendarView.swift`
- Create: `PayDay/Views/Calendar/MonthGridView.swift`
- Create: `PayDay/Views/Calendar/MonthlyTotalBar.swift`

- [ ] **Step 1: MonthGridView 작성**

```swift
// MonthGridView.swift
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
```

- [ ] **Step 2: MonthlyTotalBar 작성**

```swift
// MonthlyTotalBar.swift
import SwiftUI

struct MonthlyTotalBar: View {
    let monthName: String
    let total: Decimal

    var body: some View {
        HStack {
            Text("\(monthName) total")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(total, format: .currency(code: "KRW").precision(.fractionLength(0)))
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
}
```

- [ ] **Step 3: CalendarView 전체 구현**

```swift
// CalendarView.swift
import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Subscription.firstPaymentDate) private var subscriptions: [Subscription]
    @State private var displayedMonth = Calendar.current.component(.month, from: .now)
    @State private var displayedYear = Calendar.current.component(.year, from: .now)
    @State private var selectedDay: Int?

    private var monthName: String {
        let components = DateComponents(year: displayedYear, month: displayedMonth)
        let date = Calendar.current.date(from: components)!
        return date.formatted(.dateTime.month(.wide))
    }

    private var eventDates: [Int: [SubscriptionCategory]] {
        var result: [Int: [SubscriptionCategory]] = [:]
        for sub in subscriptions {
            let nextDate = sub.nextPaymentDate
            let calendar = Calendar.current
            let month = calendar.component(.month, from: nextDate)
            let year = calendar.component(.year, from: nextDate)
            if month == displayedMonth && year == displayedYear {
                let day = calendar.component(.day, from: nextDate)
                result[day, default: []].append(sub.category)
            }
        }
        return result
    }

    private var selectedDaySubscriptions: [Subscription] {
        guard let selectedDay else { return [] }
        return subscriptions.filter { sub in
            let calendar = Calendar.current
            let nextDate = sub.nextPaymentDate
            return calendar.component(.day, from: nextDate) == selectedDay
                && calendar.component(.month, from: nextDate) == displayedMonth
                && calendar.component(.year, from: nextDate) == displayedYear
        }
    }

    private var monthTotal: Decimal {
        subscriptions
            .filter { sub in
                let calendar = Calendar.current
                let nextDate = sub.nextPaymentDate
                return calendar.component(.month, from: nextDate) == displayedMonth
                    && calendar.component(.year, from: nextDate) == displayedYear
            }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigationHeader
                MonthGridView(
                    year: displayedYear,
                    month: displayedMonth,
                    eventDates: eventDates,
                    selectedDay: $selectedDay
                )

                if !selectedDaySubscriptions.isEmpty {
                    selectedDayDetail
                }

                Spacer()

                MonthlyTotalBar(monthName: monthName, total: monthTotal)
                    .padding(.bottom, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
        }
    }

    private var monthNavigationHeader: some View {
        HStack {
            Text("\(monthName) \(String(displayedYear))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(PayDayColor.brand)
            Spacer()
            HStack(spacing: 22) {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundStyle(PayDayColor.brand)
                }
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .foregroundStyle(PayDayColor.brand)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var selectedDayDetail: some View {
        let calendar = Calendar.current
        let components = DateComponents(year: displayedYear, month: displayedMonth, day: selectedDay)
        let date = calendar.date(from: components)

        VStack(alignment: .leading, spacing: 8) {
            if let date {
                Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 20)
                    .padding(.top, 20)
            }

            VStack(spacing: 0) {
                ForEach(Array(selectedDaySubscriptions.enumerated()), id: \.element.persistentModelID) { index, sub in
                    SubscriptionRow(subscription: sub)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                    if index < selectedDaySubscriptions.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }

    private func changeMonth(by value: Int) {
        var components = DateComponents(year: displayedYear, month: displayedMonth)
        components.month! += value
        let date = Calendar.current.date(from: components)!
        displayedMonth = Calendar.current.component(.month, from: date)
        displayedYear = Calendar.current.component(.year, from: date)
        selectedDay = nil
    }
}
```

- [ ] **Step 4: 빌드 확인**

Run: `xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 커밋**

```bash
git add Views/Calendar/
git commit -m "[Feat] - Calendar 탭 구현

What?
- MonthGridView 월간 그리드 (요일 헤더 + 날짜 셀 + neutral dot 이벤트)
- 날짜 탭 시 해당일 구독 상세 표시
- MonthlyTotalBar 하단 sticky 월간 총액
- 월 네비게이션 (이전/다음 월)"
```

---

## Task 6: Settings 탭 구현

**Files:**
- Modify: `PayDay/Views/Settings/SettingsView.swift`

- [ ] **Step 1: SettingsView 전체 구현**

```swift
// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("isRemindOneDayBefore") private var isRemindOneDayBefore = true
    @AppStorage("isRemindThreeDaysBefore") private var isRemindThreeDaysBefore = false
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("currencyCode") private var currencyCode = "KRW"
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = true

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                preferencesSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: $isRemindOneDayBefore) {
                Label("Notify D-1 before payment", systemImage: "bell.fill")
            }
            Toggle(isOn: $isRemindThreeDaysBefore) {
                Label("Notify D-3 before payment", systemImage: "bell.fill")
            }
            LabeledContent {
                Text("\(notificationHour):00 AM")
            } label: {
                Label("Time", systemImage: "clock")
            }
        }
        .tint(PayDayColor.brand)
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            LabeledContent {
                Text(currencyCode == "KRW" ? "KRW (₩)" : currencyCode)
            } label: {
                Label("Currency", systemImage: "wonsign")
            }
            LabeledContent {
                Text(weekStartsOnMonday ? "Monday" : "Sunday")
            } label: {
                Label("Week starts on", systemImage: "calendar")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
            } label: {
                Label("Version", systemImage: "info.circle")
            }
            Link(destination: URL(string: "https://apps.apple.com")!) {
                Label("Rate the app", systemImage: "heart.fill")
            }
            Link(destination: URL(string: "mailto:devmutopia@gmail.com")!) {
                Label("Contact support", systemImage: "envelope.fill")
            }
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run: `xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add Views/Settings/
git commit -m "[Feat] - Settings 탭 구현

What?
- Notifications 섹션 (D-1/D-3 토글, 시간)
- Preferences 섹션 (통화, 주 시작일)
- About 섹션 (버전, 앱 평가, 문의)
- AppStorage로 설정 영속화"
```

---

## Task 7: Add Subscription 시트 구현

**Files:**
- Create: `PayDay/Views/AddSubscription/AddSubscriptionSearchView.swift`
- Create: `PayDay/Views/AddSubscription/AddSubscriptionDetailView.swift`

- [ ] **Step 1: AddSubscriptionSearchView 작성**

```swift
// AddSubscriptionSearchView.swift
import SwiftUI

struct AddSubscriptionSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: SubscriptionCategory?
    @State private var selectedPreset: PresetService?

    private var filteredServices: [PresetService] {
        PresetService.all.filter { service in
            let matchesSearch = searchText.isEmpty || service.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || service.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                categoryChips
                serviceList
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedPreset) { preset in
                AddSubscriptionDetailView(preset: preset)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
            TextField("Search services", text: $searchText)
                .font(.body)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.quaternarySystemFill), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", isSelected: selectedCategory == nil)
                    .onTapGesture { selectedCategory = nil }
                ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                    CategoryChip(title: category.displayName, isSelected: selectedCategory == category)
                        .onTapGesture { selectedCategory = category }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }

    private var serviceList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(filteredServices.enumerated()), id: \.element.id) { index, service in
                    Button {
                        selectedPreset = service
                    } label: {
                        HStack(spacing: 12) {
                            ServiceIconView(category: service.category)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(service.name).font(.body).foregroundStyle(.primary)
                                Text("\(service.category.displayName) · \(service.defaultAmount, format: .currency(code: "KRW").precision(.fractionLength(0)))/mo")
                                    .font(.footnote).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).fontWeight(.semibold).foregroundStyle(.quaternary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                    }
                    if index < filteredServices.count - 1 {
                        Divider().padding(.leading, 68)
                    }
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)

            Button {
                selectedPreset = PresetService(name: "", category: .other, defaultAmount: 0)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                    Text("Add custom service")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(PayDayColor.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }
}
```

- [ ] **Step 2: AddSubscriptionDetailView 작성**

```swift
// AddSubscriptionDetailView.swift
import SwiftUI
import SwiftData

struct AddSubscriptionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let preset: PresetService

    @State private var name: String
    @State private var amount: Decimal
    @State private var billingCycle: BillingCycle = .monthly
    @State private var firstPaymentDate: Date = .now
    @State private var category: SubscriptionCategory
    @State private var isRemindOneDayBefore = true
    @State private var isRemindThreeDaysBefore = false
    @State private var note = ""

    init(preset: PresetService) {
        self.preset = preset
        _name = State(initialValue: preset.name)
        _amount = State(initialValue: preset.defaultAmount)
        _category = State(initialValue: preset.category)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    serviceHeader
                    planSection
                    remindersSection
                    noteSection
                    addButton
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(name.isEmpty ? "New service" : name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty || amount <= 0)
                }
            }
        }
    }

    private var serviceHeader: some View {
        VStack(spacing: 10) {
            ServiceIconView(category: category, size: 72)
            if preset.name.isEmpty {
                TextField("Service name", text: $name)
                    .font(.title2).fontWeight(.bold)
                    .multilineTextAlignment(.center)
            } else {
                Text(name).font(.title2).fontWeight(.bold)
            }
            Text(category.displayName).font(.footnote).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 20)
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plan").font(.footnote).fontWeight(.semibold).foregroundStyle(.tertiary).padding(.leading, 20)
            VStack(spacing: 0) {
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("₩0", value: $amount, format: .currency(code: "KRW").precision(.fractionLength(0)))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Billing")
                    Spacer()
                    Picker("Billing", selection: $billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Text(cycle.displayName).tag(cycle)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                DatePicker("First payment", selection: $firstPaymentDate, displayedComponents: .date)
                    .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Category")
                    Spacer()
                    Picker("Category", selection: $category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 11)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders").font(.footnote).fontWeight(.semibold).foregroundStyle(.tertiary).padding(.leading, 20).padding(.top, 20)
            VStack(spacing: 0) {
                Toggle("D-1 reminder", isOn: $isRemindOneDayBefore)
                    .padding(.horizontal, 16).padding(.vertical, 11)
                    .tint(PayDayColor.brand)
                Divider().padding(.leading, 16)
                Toggle("D-3 reminder", isOn: $isRemindThreeDaysBefore)
                    .padding(.horizontal, 16).padding(.vertical, 11)
                    .tint(PayDayColor.brand)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note").font(.footnote).fontWeight(.semibold).foregroundStyle(.tertiary).padding(.leading, 20).padding(.top, 20)
            TextField("Optional · e.g. \"Family plan\"", text: $note, axis: .vertical)
                .lineLimit(3...)
                .padding(14)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
        }
    }

    private var addButton: some View {
        Button { save() } label: {
            Text("Add subscription")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(PayDayColor.brand, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: PayDayColor.brand.opacity(0.3), radius: 14, y: 4)
        }
        .disabled(name.isEmpty || amount <= 0)
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private func save() {
        let subscription = Subscription(
            name: name,
            amount: amount,
            billingCycle: billingCycle,
            firstPaymentDate: firstPaymentDate,
            category: category,
            note: note,
            isRemindOneDayBefore: isRemindOneDayBefore,
            isRemindThreeDaysBefore: isRemindThreeDaysBefore
        )
        modelContext.insert(subscription)
        dismiss()
        // 부모 시트도 닫기 위해 한 번 더 dismiss 필요 — Task 9에서 처리
    }
}
```

- [ ] **Step 3: PresetService에 Identifiable 확인하고 빌드**

Run: `xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 커밋**

```bash
git add Views/AddSubscription/
git commit -m "[Feat] - Add Subscription 시트 구현

What?
- AddSubscriptionSearchView (검색 + 카테고리 chip 필터 + 프리셋 리스트)
- AddSubscriptionDetailView (Plan/Reminders/Note 폼 + Save)
- Custom service 추가 지원"
```

---

## Task 8: NotificationManager 구현

**Files:**
- Create: `PayDay/Services/NotificationManager.swift`
- Modify: `PayDay/PayDayApp.swift`

- [ ] **Step 1: NotificationManager 작성**

```swift
// NotificationManager.swift
import UserNotifications
import SwiftData

struct NotificationManager {
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleNotifications(for subscription: Subscription) {
        let center = UNUserNotificationCenter.current()

        if subscription.isRemindOneDayBefore {
            scheduleNotification(
                center: center,
                subscription: subscription,
                daysBefore: 1
            )
        }
        if subscription.isRemindThreeDaysBefore {
            scheduleNotification(
                center: center,
                subscription: subscription,
                daysBefore: 3
            )
        }
    }

    static func removeNotifications(for subscription: Subscription) {
        let center = UNUserNotificationCenter.current()
        let id = subscription.persistentModelID.hashValue
        center.removePendingNotificationRequests(withIdentifiers: [
            "payday-d1-\(id)",
            "payday-d3-\(id)",
        ])
    }

    private static func scheduleNotification(
        center: UNUserNotificationCenter,
        subscription: Subscription,
        daysBefore: Int
    ) {
        let calendar = Calendar.current
        guard let notifyDate = calendar.date(
            byAdding: .day, value: -daysBefore, to: subscription.nextPaymentDate
        ) else { return }

        guard notifyDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "PayDay"
        content.body = "\(subscription.name) 결제 D-\(daysBefore) (\(subscription.amount)원)"
        content.sound = .default

        var components = calendar.dateComponents([.year, .month, .day], from: notifyDate)
        components.hour = 9

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = subscription.persistentModelID.hashValue
        let request = UNNotificationRequest(
            identifier: "payday-d\(daysBefore)-\(id)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
```

- [ ] **Step 2: PayDayApp에 알림 권한 요청 추가**

```swift
// PayDayApp.swift
import SwiftUI
import SwiftData

@main
struct PayDayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    _ = await NotificationManager.requestAuthorization()
                }
        }
        .modelContainer(for: Subscription.self)
    }
}
```

- [ ] **Step 3: AddSubscriptionDetailView의 save()에 알림 스케줄링 추가**

`AddSubscriptionDetailView.swift`의 `save()` 메서드 맨 끝에 추가:
```swift
NotificationManager.scheduleNotifications(for: subscription)
```

- [ ] **Step 4: 빌드 확인**

Run: `xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 커밋**

```bash
git add Services/ PayDayApp.swift Views/AddSubscription/AddSubscriptionDetailView.swift
git commit -m "[Feat] - 결제 알림 시스템 구현

What?
- NotificationManager (D-1/D-3 알림 스케줄링/제거)
- 앱 시작 시 알림 권한 요청
- 구독 추가 시 자동 알림 스케줄링"
```

---

## Task 9: iCloud 동기화 설정

**Files:**
- Modify: `PayDay/PayDayApp.swift`

- [ ] **Step 1: ModelContainer에 CloudKit 활성화**

```swift
// PayDayApp.swift
import SwiftUI
import SwiftData

@main
struct PayDayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    _ = await NotificationManager.requestAuthorization()
                }
        }
        .modelContainer(
            for: Subscription.self,
            configurations: ModelConfiguration(cloudKitDatabase: .automatic)
        )
    }
}
```

- [ ] **Step 2: Xcode에서 iCloud capability 추가**

수동 작업 필요:
1. Xcode → PayDay target → Signing & Capabilities
2. "+ Capability" → "iCloud" 추가
3. "CloudKit" 체크
4. Container: `iCloud.com.moolab.PayDay` 생성

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 커밋**

```bash
git add PayDayApp.swift PayDay.xcodeproj/
git commit -m "[Feat] - iCloud 동기화 설정

What?
- SwiftData ModelConfiguration에 CloudKit 자동 동기화 활성화
- iCloud capability + CloudKit 컨테이너 설정"
```

---

## Task 10: WidgetKit Extension 생성 및 위젯 구현

**Files:**
- Create: `PayDayWidgets/PayDayWidgets.swift`
- Create: `PayDayWidgets/WidgetTimelineProvider.swift`
- Create: `PayDayWidgets/SmallDdayWidget.swift`
- Create: `PayDayWidgets/SmallTotalWidget.swift`
- Create: `PayDayWidgets/MediumUpcomingWidget.swift`

- [ ] **Step 1: Xcode에서 Widget Extension 타겟 추가**

수동 작업 필요:
1. Xcode → File → New → Target → Widget Extension
2. Product Name: `PayDayWidgets`
3. "Include Configuration App Intent" 체크 해제
4. App Group 생성: `group.com.moolab.PayDay`
5. 메인 앱 타겟에도 같은 App Group 추가
6. 위젯 타겟에 SwiftData import 가능하도록 모델 파일을 shared target membership으로 설정

- [ ] **Step 2: WidgetTimelineProvider 작성**

```swift
// WidgetTimelineProvider.swift
import WidgetKit
import SwiftData

struct SubscriptionEntry: TimelineEntry {
    let date: Date
    let subscriptions: [WidgetSubscription]
    let monthlyTotal: Decimal
}

struct WidgetSubscription: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let amount: Decimal
    let nextPaymentDate: Date
    let daysUntil: Int
}

struct PayDayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SubscriptionEntry {
        SubscriptionEntry(
            date: .now,
            subscriptions: [
                WidgetSubscription(name: "Netflix", category: "streaming", amount: 17000, nextPaymentDate: .now, daysUntil: 2),
                WidgetSubscription(name: "Claude", category: "ai", amount: 28000, nextPaymentDate: .now, daysUntil: 5),
            ],
            monthlyTotal: 95200
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SubscriptionEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubscriptionEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SubscriptionEntry {
        do {
            let container = try ModelContainer(for: Subscription.self)
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Subscription>()
            let subs = try context.fetch(descriptor)

            let widgetSubs = subs
                .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
                .prefix(4)
                .map { sub in
                    WidgetSubscription(
                        name: sub.name,
                        category: sub.category.rawValue,
                        amount: sub.amount,
                        nextPaymentDate: sub.nextPaymentDate,
                        daysUntil: sub.daysUntilNextPayment
                    )
                }

            let total = subs.reduce(Decimal.zero) { $0 + $1.monthlyAmount }
            return SubscriptionEntry(date: .now, subscriptions: Array(widgetSubs), monthlyTotal: total)
        } catch {
            return placeholder(in: .init())
        }
    }
}
```

- [ ] **Step 3: SmallDdayWidget 작성**

```swift
// SmallDdayWidget.swift
import SwiftUI
import WidgetKit

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
                    widgetIcon(for: next.category)
                    Spacer()
                    Text(next.nextPaymentDate, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("D-\(next.daysUntil)")
                    .font(.system(size: 38, weight: .heavy))
                    .foregroundStyle(Color(red: 49/255, green: 130/255, blue: 246/255))
                    .monospacedDigit()

                Text(next.amount, format: .currency(code: "KRW").precision(.fractionLength(0)))
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

    private func widgetIcon(for category: String) -> some View {
        let systemName: String = switch category {
        case "streaming": "play.fill"
        case "ai": "sparkle"
        case "productivity": "doc.text.fill"
        default: "clock"
        }
        return RoundedRectangle(cornerRadius: 6)
            .fill(Color(.tertiarySystemFill))
            .frame(width: 28, height: 28)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
    }
}
```

- [ ] **Step 4: SmallTotalWidget 작성**

```swift
// SmallTotalWidget.swift
import SwiftUI
import WidgetKit

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
            Text(entry.date, format: .dateTime.month(.wide).locale(Locale(identifier: "en")))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()

            Text(entry.monthlyTotal, format: .currency(code: "KRW").precision(.fractionLength(0)))
                .font(.system(size: 28, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("across \(entry.subscriptions.count) services")
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
```

- [ ] **Step 5: MediumUpcomingWidget 작성**

```swift
// MediumUpcomingWidget.swift
import SwiftUI
import WidgetKit

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
                    widgetIcon(for: sub.category)
                    Text(sub.name)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    Text(sub.nextPaymentDate, format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 44, alignment: .trailing)
                    Text(sub.amount, format: .currency(code: "KRW").precision(.fractionLength(0)))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .frame(minWidth: 64, alignment: .trailing)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func widgetIcon(for category: String) -> some View {
        let systemName: String = switch category {
        case "streaming": "play.fill"
        case "ai": "sparkle"
        case "productivity": "doc.text.fill"
        default: "clock"
        }
        return RoundedRectangle(cornerRadius: 5)
            .fill(Color(.tertiarySystemFill))
            .frame(width: 22, height: 22)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
    }
}
```

- [ ] **Step 6: Widget 번들 정의**

```swift
// PayDayWidgets.swift
import SwiftUI
import WidgetKit

@main
struct PayDayWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallDdayWidget()
        SmallTotalWidget()
        MediumUpcomingWidget()
    }
}
```

- [ ] **Step 7: 빌드 확인**

Run: `xcodebuild build -scheme PayDayWidgets -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 8: 커밋**

```bash
git add PayDayWidgets/ PayDay.xcodeproj/
git commit -m "[Feat] - WidgetKit 위젯 3종 구현

What?
- SmallDdayWidget (다음 결제 D-day + 금액 + 서비스명)
- SmallTotalWidget (월간 총액 + 서비스 수 + 다음 결제 요약)
- MediumUpcomingWidget (다가올 결제 4건 리스트)
- PayDayTimelineProvider로 SwiftData에서 데이터 로드"
```

---

## Task 11: 구독 편집/삭제 기능

**Files:**
- Modify: `PayDay/Views/Home/HomeView.swift`
- Create: `PayDay/Views/AddSubscription/EditSubscriptionView.swift`

- [ ] **Step 1: EditSubscriptionView 작성 (AddSubscriptionDetailView 기반)**

```swift
// EditSubscriptionView.swift
import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var subscription: Subscription

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    serviceHeader
                    planSection
                    remindersSection
                    noteSection
                    deleteButton
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(subscription.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        NotificationManager.removeNotifications(for: subscription)
                        NotificationManager.scheduleNotifications(for: subscription)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var serviceHeader: some View {
        VStack(spacing: 10) {
            ServiceIconView(category: subscription.category, size: 72)
            Text(subscription.name).font(.title2).fontWeight(.bold)
            Text(subscription.category.displayName).font(.footnote).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 20)
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plan").font(.footnote).fontWeight(.semibold).foregroundStyle(.tertiary).padding(.leading, 20)
            VStack(spacing: 0) {
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("₩0", value: $subscription.amount, format: .currency(code: "KRW").precision(.fractionLength(0)))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .fontWeight(.semibold).monospacedDigit()
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Billing")
                    Spacer()
                    Picker("Billing", selection: $subscription.billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }.pickerStyle(.segmented).frame(width: 160)
                }
                .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                DatePicker("First payment", selection: $subscription.firstPaymentDate, displayedComponents: .date)
                    .padding(.horizontal, 16).padding(.vertical, 11)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Category")
                    Spacer()
                    Picker("Category", selection: $subscription.category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 11)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders").font(.footnote).fontWeight(.semibold).foregroundStyle(.tertiary).padding(.leading, 20).padding(.top, 20)
            VStack(spacing: 0) {
                Toggle("D-1 reminder", isOn: $subscription.isRemindOneDayBefore)
                    .padding(.horizontal, 16).padding(.vertical, 11).tint(PayDayColor.brand)
                Divider().padding(.leading, 16)
                Toggle("D-3 reminder", isOn: $subscription.isRemindThreeDaysBefore)
                    .padding(.horizontal, 16).padding(.vertical, 11).tint(PayDayColor.brand)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note").font(.footnote).fontWeight(.semibold).foregroundStyle(.tertiary).padding(.leading, 20).padding(.top, 20)
            TextField("Optional", text: $subscription.note, axis: .vertical)
                .lineLimit(3...)
                .padding(14)
                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            NotificationManager.removeNotifications(for: subscription)
            modelContext.delete(subscription)
            dismiss()
        } label: {
            Text("Delete subscription")
                .font(.body)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .padding(.top, 24)
    }
}
```

- [ ] **Step 2: HomeView의 SubscriptionRow에 탭 → 편집 sheet 연결**

HomeView의 SubscriptionRow를 Button으로 감싸고 `@State private var selectedSubscription: Subscription?` 추가.
`.sheet(item: $selectedSubscription)` 으로 `EditSubscriptionView` 표시.

각 SubscriptionRow를 다음과 같이 변경:
```swift
Button {
    selectedSubscription = sub
} label: {
    SubscriptionRow(subscription: sub)
}
```

- [ ] **Step 3: 빌드 확인**

Run: `xcodebuild build -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 커밋**

```bash
git add Views/AddSubscription/EditSubscriptionView.swift Views/Home/HomeView.swift
git commit -m "[Feat] - 구독 편집/삭제 기능 구현

What?
- EditSubscriptionView (기존 구독 수정 + 삭제)
- HomeView에서 구독 탭 시 편집 시트 표시
- 편집/삭제 시 알림 갱신"
```

---

## Task 12: 프로젝트 CLAUDE.md 생성 및 최종 정리

**Files:**
- Create: `PayDay/CLAUDE.md`

- [ ] **Step 1: 프로젝트 CLAUDE.md 작성**

```markdown
# PayDay — Project Rules

## Project Overview
- **Platform:** iOS
- **Distribution:** App Store
- **UI Framework:** SwiftUI
- **Minimum OS:** iOS 26.4
- **Architecture:** Single-target + WidgetKit Extension
- **Data:** SwiftData + iCloud (CloudKit)

## SwiftUI View Rules
- When a view body's Stack nesting depth exceeds 2 levels, extract inner stacks into separate subviews immediately.
- Each subview should have a single, clear responsibility.
- Prefer small, composable views over deeply nested view trees.

## Code Style
- Follow Swift API Design Guidelines for all naming.
- Use Swift Concurrency (async/await, actors) over GCD/completion handlers.
- Prefer value types (struct, enum) over reference types unless shared mutable state is required.
- Mark classes as `final` by default.
- Use `private` access control by default; widen only when needed.

## Design Reference
- Handoff bundle: `/tmp/payday/`
- Design tokens: `hifi-tokens.jsx` (Toss-style calm blue #3182F6)
- Light mode only. No dark mode.

## Testing
- Write unit tests for all business logic and view models.
- Use Swift Testing framework (`@Test`, `#expect`) over XCTest for new tests.

## Commit Language
- Korean (see git-conventions.md)
```

- [ ] **Step 2: 빌드 + 전체 테스트 실행**

Run: `xcodebuild test -scheme PayDay -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: All tests PASS

- [ ] **Step 3: 커밋**

```bash
git add CLAUDE.md
git commit -m "[Docs] - 프로젝트 CLAUDE.md 생성

What?
- 프로젝트 개요, 아키텍처, 코드 스타일 규칙 정의
- 디자인 레퍼런스 경로 포함"
```

---

## Summary

| Task | 내용 | 예상 파일 수 |
|------|------|:---:|
| 1 | SwiftData 모델 + 기본 타입 + 테스트 | 5 |
| 2 | 디자인 토큰 + 공통 컴포넌트 | 4 |
| 3 | App 진입점 + TabView | 5 |
| 4 | Home 탭 | 3 |
| 5 | Calendar 탭 | 3 |
| 6 | Settings 탭 | 1 |
| 7 | Add Subscription 시트 | 2 |
| 8 | NotificationManager | 1 |
| 9 | iCloud 동기화 | 1 |
| 10 | WidgetKit 위젯 3종 | 6 |
| 11 | 편집/삭제 기능 | 2 |
| 12 | CLAUDE.md + 최종 정리 | 1 |
