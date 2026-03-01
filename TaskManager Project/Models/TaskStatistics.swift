import SwiftUI

struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let overdueTasks: Int
    let todayTasks: Int
    let completionRate: Double
    let tasksCompletedToday: Int
    let averageCompletionTime: TimeInterval
    
    var completionRateString: String {
        String(format: "%.0f%%", completionRate * 100)
    }
    
    // Formatted average time
    var formattedAverageTime: String {
        guard averageCompletionTime > 0 else { return "N/A" }
        let hours = Int(averageCompletionTime) / 3600
        let minutes = Int(averageCompletionTime) / 60 % 60
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}
