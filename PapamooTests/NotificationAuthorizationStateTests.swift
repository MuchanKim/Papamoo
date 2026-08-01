import Testing
import UserNotifications
@testable import Papamoo

struct NotificationAuthorizationStateTests {
    @Test(
        "시스템 알림 권한을 설정 화면 상태로 변환한다",
        arguments: [
            (UNAuthorizationStatus.notDetermined, NotificationAuthorizationState.notDetermined),
            (.authorized, .authorized),
            (.provisional, .authorized),
            (.ephemeral, .authorized),
            (.denied, .denied),
        ]
    )
    func mapsAuthorizationStatus(
        status: UNAuthorizationStatus,
        expectedState: NotificationAuthorizationState
    ) {
        #expect(NotificationAuthorizationState(status: status) == expectedState)
    }
}
