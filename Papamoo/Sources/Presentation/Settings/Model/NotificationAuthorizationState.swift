import UserNotifications

nonisolated enum NotificationAuthorizationState: Equatable {
    case loading
    case notDetermined
    case authorized
    case denied
    case unavailable

    init(status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorized, .provisional, .ephemeral:
            self = .authorized
        case .denied:
            self = .denied
        @unknown default:
            self = .unavailable
        }
    }
}
