import Foundation
import UserNotifications

enum WeeklyFundSyncReminder {
    static let enabledKey = "weeklyFundSyncReminderEnabled"
    private static let notificationID = "weekly-fund-sync-reminder"

    static func setEnabled(_ enabled: Bool) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        guard enabled else { return }

        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else { throw ReminderError.authorizationDenied }

        let content = UNMutableNotificationContent()
        content.title = "更新基金持仓"
        content.body = "从基金 E 账户导出持有信息，Mocha 会自动识别邮件中的 XLSX。"
        content.sound = .default

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.weekday = 1
        components.hour = 20
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try await center.add(UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger))
    }

    enum ReminderError: LocalizedError {
        case authorizationDenied

        var errorDescription: String? {
            "通知权限未开启，请在系统设置中允许 Mocha 发送通知"
        }
    }
}
