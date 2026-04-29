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
        let center = UNUserNotificationCenter.current()
        let id = subscription.persistentModelID.hashValue
        center.removePendingNotificationRequests(withIdentifiers: [
            "payday-d1-\(id)",
            "payday-d3-\(id)",
        ])
    }

    /// Cancels and re-schedules notifications for every subscription. Use after global reminder settings change.
    static func rescheduleAll(in context: ModelContext) {
        let descriptor = FetchDescriptor<Subscription>()
        guard let subs = try? context.fetch(descriptor) else { return }
        for sub in subs {
            removeNotifications(for: sub)
            scheduleNotifications(for: sub)
        }
    }

    private static func scheduleNotification(
        center: UNUserNotificationCenter,
        subscription: Subscription,
        daysBefore: Int,
        hour: Int
    ) {
        let calendar = Calendar.current
        guard let notifyDate = calendar.date(
            byAdding: .day, value: -daysBefore, to: subscription.nextPaymentDate
        ) else { return }

        guard notifyDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Papamoo"
        content.body = "\(subscription.name) 결제 D-\(daysBefore) (\(subscription.amount)원)"
        content.sound = .default

        var components = calendar.dateComponents([.year, .month, .day], from: notifyDate)
        components.hour = hour

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
