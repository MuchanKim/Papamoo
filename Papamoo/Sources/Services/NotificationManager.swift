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
        let id = notificationIdentifier(for: subscription)
        center.removePendingNotificationRequests(withIdentifiers: [
            requestIdentifier(daysBefore: 1, subscriptionID: id),
            requestIdentifier(daysBefore: 3, subscriptionID: id),
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
        guard let notifyDate = notificationDate(
            for: subscription.nextPaymentDate,
            daysBefore: daysBefore,
            hour: hour,
            calendar: calendar
        ) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Papamoo"
        content.body = "\(subscription.name) 결제 D-\(daysBefore) (\(subscription.amount)원)"
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notifyDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = notificationIdentifier(for: subscription)
        let request = UNNotificationRequest(
            identifier: requestIdentifier(daysBefore: daysBefore, subscriptionID: id),
            content: content,
            trigger: trigger
        )
        center.add(request)
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

    private static func notificationIdentifier(for subscription: Subscription) -> String {
        String(describing: subscription.persistentModelID)
    }

    private static func requestIdentifier(daysBefore: Int, subscriptionID: String) -> String {
        "payday-d\(daysBefore)-\(subscriptionID)"
    }
}
