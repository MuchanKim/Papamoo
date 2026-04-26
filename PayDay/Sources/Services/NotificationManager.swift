import SwiftData
import UserNotifications

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
