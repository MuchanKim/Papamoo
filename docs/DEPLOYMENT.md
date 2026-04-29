# PayDay 배포 가이드

iOS App Store 배포에 필요한 절차. 코드/프로젝트 측 준비는 commit으로 완료, **사용자 수동 작업 항목**만 정리.

## 코드/프로젝트 측 준비 (완료)

- ✅ `PayDay/PrivacyInfo.xcprivacy` — UserDefaults + FileTimestamp 사용 declared
- ✅ `Info.plist` `ITSAppUsesNonExemptEncryption = false` (standard HTTPS만 사용)
- ✅ `Info.plist` `UILaunchScreen` + `LaunchBackground` colorset (검정 #0A0A0A)
- ✅ `Info.plist` `UIAppFonts` (IBM Plex Mono 4 weight)
- ✅ App Group `group.com.moolab.PayDay` 등록 + entitlements
- ✅ Marketing Version `1.0` / Build Number `1`

## 사용자 수동 작업 (App Store 출시 전 필수)

### 1. App Icon

`PayDay/Resources/Assets.xcassets/AppIcon.appiconset/` 에 1024×1024 PNG 한 장 추가.

- iOS 14+는 **단일 1024×1024** PNG로 충분 (`Contents.json`에 single size entry)
- 다양한 크기는 Xcode가 자동 생성
- 디자인: brutalist 톤과 일관 — 검정 배경 + 노랑 ₩ 또는 mono "P" 같은 단순 형태 권장
- 권장 도구: Figma, Sketch, 또는 [bakery.app](https://bakery.app) (icon generator)

### 2. PayDayWidgetExtension에 폰트 Target Membership 추가

위젯에서 IBM Plex Mono를 정상 표시하려면 4개 ttf 파일을 위젯 타깃에도 멤버십 추가.

1. Xcode Project Navigator → `PayDay/Resources/Fonts/` 펼치기
2. 4개 ttf 파일 모두 선택 (⌘+클릭으로 다중)
3. 우측 File Inspector → Target Membership → **PayDayWidgetExtension** 체크

안 하면 위젯에서 시스템 monospace fallback (앱 본체는 정상).

### 3. App Store Connect 앱 등록

1. [App Store Connect](https://appstoreconnect.apple.com) → My Apps → **+** → New App
2. 입력:
   - **Platforms**: iOS
   - **Name**: PayDay
   - **Primary Language**: Korean (또는 English)
   - **Bundle ID**: `com.moolab.PayDay` (이미 Apple Developer Console에 등록됨)
   - **SKU**: `payday-001` 등 자유
   - **User Access**: Full Access

### 4. App Store 메타데이터

App Store Connect의 앱 페이지에서:
- **Description** (한/영/일 — Localizable.xcstrings 톤과 맞춤)
- **Keywords** (예: 구독, subscription, 결제, payment, 가계부, fintech)
- **Support URL** / **Marketing URL** (없으면 GitHub repo URL)
- **Screenshots**: iPhone 6.7" + iPhone 6.5" 필수. 시뮬레이터에서 ⌘+S 캡쳐. 4-10장 권장.
- **App Privacy**: 데이터 수집 없음 declare (PayDay는 수집 안 함, App Group 로컬 저장만)

### 5. Build & Archive

1. Xcode 좌상단 destination을 **Any iOS Device (arm64)** 로 변경
2. Product → **Archive** (⌘+Shift+B 후 ⌘+B 아님 — 메뉴 사용)
3. Organizer 자동 열림 → **Distribute App** → **App Store Connect** → **Upload**
4. 자동 서명 사용 시 Apple이 알아서 처리. 수동 서명이면 Distribution provisioning profile 필요

### 6. TestFlight (선택, 권장)

App Store Connect → 해당 앱 → TestFlight 탭 → 업로드된 빌드를 Internal Testing 에 추가 → 본인 + 베타 테스터에게 초대. 며칠 사용 후 이슈 없으면 App Store 제출.

### 7. App Store 제출

App Store Connect → 앱 → "1.0 Prepare for Submission" → 빌드 선택 → Submit for Review. 보통 24-48시간 소요.

## 출시 후 처리

- **Rate the app** Link URL을 실제 App Store ID로 교체:
  ```swift
  Link(destination: URL(string: "https://apps.apple.com/app/idXXXXXXXXX?action=write-review")!) { ... }
  ```
  또는 `SKStoreReviewController.requestReview()` 사용 (iOS 14+)
- App Store 리뷰 수집 → 다음 버전 우선순위 결정

## 향후 작업 (v1.1+)

- CloudKit 활성화: `ModelConfiguration(cloudKitDatabase: .automatic)` + 컨테이너 provisioning
- AddSubscriptionViewModel.save() 실패 시 사용자 alert
- ExchangeRateSheetView에 ViewModel 도입
- PayDayWidget.swift 파일 분리 (현재 318줄)
- Live Activity (Lock Screen에 next payment countdown)

## 알려진 한계

- 위젯의 `monthlyTotal`이 inline 환율 환산 사용 — `ExchangeRateManager.swift`를 위젯 타깃에도 멤버십 추가하면 single source로 통일 가능 (선택)
- 다국어: en/ko/ja 3개. 추가 언어 시 `Localizable.xcstrings` 확장
