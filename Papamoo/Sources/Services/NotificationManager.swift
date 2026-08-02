import OSLog
import SwiftData
import UserNotifications

struct NotificationManager {

    // MARK: - Properties

    private nonisolated static let logger = Logger(
        subsystem: "com.moolab.Papamoo",
        category: "Notifications"
    )

    // MARK: - Methods

    static func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func scheduleNotifications(for subscription: Subscription) {
        let center = UNUserNotificationCenter.current()
        let defaults = UserDefaults.appGroup
        let isRemindOneDay = defaults.object(forKey: "isRemindOneDayBefore") as? Bool ?? true
        let isRemindThreeDays = defaults.bool(forKey: "isRemindThreeDaysBefore")
        let hour = defaults.object(forKey: "notificationHour") as? Int ?? 9

        if isRemindOneDay {
            scheduleNotification(center: center, subscription: subscription, daysBefore: 1, hour: hour)
        }
        if isRemindThreeDays {
            scheduleNotification(center: center, subscription: subscription, daysBefore: 3, hour: hour)
        }
    }

    static func removeNotifications(for subscription: Subscription) {
        removeNotifications(for: subscription.persistentModelID)
    }

    static func removeNotifications(for id: PersistentIdentifier) {
        let center = UNUserNotificationCenter.current()
        let identifier = id.hashValue
        center.removePendingNotificationRequests(withIdentifiers: [
            "payday-d1-\(identifier)",
            "payday-d3-\(identifier)",
        ])
    }

    static func rescheduleAll(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Subscription>()
        let subscriptions = try context.fetch(descriptor)
        let center = UNUserNotificationCenter.current()

        // 프로세스마다 달라지는 hash 기반 식별자가 남지 않도록 앱이 소유한 알림을 모두 재구성한다.
        center.removeAllPendingNotificationRequests()
        for subscription in subscriptions {
            scheduleNotifications(for: subscription)
        }
    }

    nonisolated static func notificationDate(
        for nextPaymentDate: Date,
        daysBefore: Int,
        hour: Int,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> Date? {
        guard let reminderDay = calendar.date(
            byAdding: .day,
            value: -daysBefore,
            to: nextPaymentDate
        ) else { return nil }

        var components = calendar.dateComponents([.year, .month, .day], from: reminderDay)
        components.hour = hour
        components.minute = 0
        components.second = 0

        guard let fireDate = calendar.date(from: components), fireDate > now else { return nil }
        return fireDate
    }

    // MARK: - Private Methods

    private static func scheduleNotification(
        center: UNUserNotificationCenter,
        subscription: Subscription,
        daysBefore: Int,
        hour: Int
    ) {
        let calendar = Calendar.current
        guard let notifyDate = notificationDate(
            for: subscription.nextPaymentDate,
            daysBefore: daysBefore,
            hour: hour,
            calendar: calendar
        ) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Papamoo"
        let bodyFormat = NSLocalizedString(
            "%1$@ payment D-%2$ld (%3$@%4$@)",
            comment: "Payment reminder body. Arguments are service name, days before payment, currency symbol, and amount."
        )
        content.body = String(
            format: bodyFormat,
            subscription.name,
            daysBefore,
            CurrencyFormatter.symbol(for: subscription.currencyCode),
            CurrencyFormatter.amountString(subscription.amount, currencyCode: subscription.currencyCode)
        )
        content.sound = .default

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notifyDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = subscription.persistentModelID.hashValue
        let request = UNNotificationRequest(
            identifier: "payday-d\(daysBefore)-\(id)",
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            guard let error else { return }
            logger.error("Notification scheduling failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
