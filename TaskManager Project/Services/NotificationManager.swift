import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Schedule Daily Summary Notification
    func scheduleDailySummary(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Task Summary"
        content.body = "Check your productivity stats and plan your day!"
        content.sound = .default
        content.badge = 1  
        content.categoryIdentifier = "DAILY_SUMMARY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily summary: \(error)")
            } else {
                print("✅ Daily summary scheduled for \(hour):\(minute)")
            }
        }
    }
    
    // MARK: - Cancel Daily Summary Notification
    func cancelDailySummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_summary"])
        print("🔕 Daily summary notification cancelled")
    }
    
    
    // MARK: - Send Immediate Daily Summary 
    func sendDailySummaryNow(statistics: TaskStatistics) {
        let content = UNMutableNotificationContent()
        content.title = "📊 Your Daily Summary"
        
        content.body = """
        ✅ Completed: \(statistics.tasksCompletedToday)
        📋 Total: \(statistics.totalTasks)
        ⏳ Pending: \(statistics.pendingTasks)
        """
        
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send daily summary: \(error)")
            } else {
                print("✅ Daily summary sent")
            }
        }
    }
    
    // MARK: - Check if Daily Summary is Scheduled 
    func isDailySummaryScheduled(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let isScheduled = requests.contains { $0.identifier == "daily_summary" }
            completion(isScheduled)
        }
    }
}
