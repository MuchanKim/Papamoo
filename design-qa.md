# Calendar Design QA

## 비교 조건

- 기준 이미지: `/Users/muchankim/.codex/generated_images/019fbce1-ecd2-7450-9f52-899f41f8bdcc/exec-24d0ea3c-82bc-4268-aaf9-68488f15cd51.png`
- 구현 캡처: `/tmp/PapamooCalendarImplementation.png`
- 나란히 비교 이미지: `/tmp/PapamooCalendarComparison.png`
- 디바이스: iPhone 17 Pro, iOS Simulator 26.4
- 캡처 크기: 1206 × 2622 px
- 비교 정규화: 두 이미지를 동일 높이로 맞춘 뒤 좌우 배치
- 검증 상태: 2026년 8월, ChatGPT 월간 구독 28,000 KRW, 8일 선택

## 전체 화면 비교

- 월·연도, 월 합계, 결제 건수, 이전/다음 월 이동, 요일 헤더, 날짜 그리드, 선택일 상세의 정보 계층이 기준안과 일치한다.
- 월 합계와 날짜별 결제 예정 금액은 키컬러로 표시되며, 일반 날짜와 보조 정보는 중립색을 유지한다.
- 기존 Papamoo의 mono typography, dark background, divider, floating tab bar 스타일을 유지했다.
- 실제 데이터가 한 건인 검증 상태라 기준 이미지보다 결제 표시 밀도는 낮지만, 셀 간격과 선택 상태는 같은 규칙으로 렌더링된다.

## 선택일 영역 비교

- 선택한 날짜는 키컬러 테두리로 구분된다.
- 선택일 제목, 합계, 결제 건수, 서비스 아이콘, 서비스명, 금액, 결제 주기가 기준안과 같은 순서로 표시된다.
- 선택 셀의 금액과 상세 영역의 합계가 모두 28,000 KRW로 일치한다.

## 확인 항목

- Typography: 기존 앱의 typography token을 유지하고 금액에 monospaced digit을 적용했다.
- Spacing: 날짜별 금액 두 줄과 선택 테두리가 겹치지 않으며, 하단 상세가 tab bar에 가려지지 않는다.
- Color: 금액과 선택 상태만 accent를 사용하고 날짜·건수·결제 주기는 중립색으로 유지한다.
- Assets: 기존 `ServiceIconView`와 SF Symbols를 재사용했다.
- Copy: 한국어 환경에서 월, 건수, 결제 주기와 접근성 문구가 현지화되어 표시된다.
- Interaction: 월 이동, 날짜 선택, 선택일 상세 갱신이 Simulator에서 정상 동작한다.
- Accessibility: 8일은 `8일, 결제 예정 28,000 KRW`로 노출되고 날짜 1일부터 31일까지 모두 탐색된다.

## 비교 이력

1. 최초 Simulator 확인에서 선행 공백 셀과 날짜 셀의 sibling `ForEach` ID가 충돌해 1~5일이 누락되는 문제를 발견했다.
2. 선행 공백 ID를 `leading-*` 문자열로 분리해 날짜 ID와 충돌하지 않도록 수정했다.
3. 재빌드·재설치 후 1~31일 전체 렌더링, 8일 금액, 선택일 상세를 다시 확인했다.

## 잔여 이슈

- P0: 없음
- P1: 없음
- P2: 없음
- P3: 기준 이미지와 테스트 데이터의 항목 수·서비스 아이콘 배경색 차이만 있으며 실제 데이터와 기존 아이콘 자산에 따른 의도된 차이다.

final result: passed
