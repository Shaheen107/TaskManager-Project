import Foundation

struct AppConstants {
    // MARK: - Firebase Collections
    static let usersCollection = "users"
    static let tasksCollection = "tasks"
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let savedTasks = "saved_tasks"
        static let lastSync = "last_sync_time"
        static let pendingSync = "pending_sync_tasks"
        static let dailySummaryEnabled = "dailySummary"
        static let dailySummaryTime = "dailySummaryTime"
        static let themePreference = "selectedTheme"
    }
    
    // MARK: - Notification IDs
    struct NotificationIDs {
        static let dailySummary = "daily_summary"
        static let taskReminder = "task_reminder"
    }
    
    // MARK: --> App Info
    struct AppInfo {
        static let name = "TaskMaster"
        static let version = "1.0.0"
        static let bundleID = "com.taskmaster.app"
    }
    
    // MARK: - Time Constants
    struct Time {
        static let syncInterval: TimeInterval = 60 // 1 minute
        static let retryDelay: TimeInterval = 5
    }
    
    // MARK: - Limits
    struct Limits {
        static let maxTaskTitleLength = 100
        static let maxTaskDescriptionLength = 500
        static let maxTasksPerUser = 1000
    }
}
