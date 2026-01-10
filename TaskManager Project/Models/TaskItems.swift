import SwiftUI

struct TaskItems: Codable, Identifiable {
    var id: UUID
    var title: String
    var description: String
    var priority: TaskPriority
    var category: TaskCategory
    var isCompleted: Bool
    var createdDate: Date
    var dueDate: Date?
    var completedDate: Date?
    var reminderDate: Date?
    
    init(title: String, description: String = "", priority: TaskPriority = .medium, category: TaskCategory = .personal, dueDate: Date? = nil, reminderDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.isCompleted = false
        self.createdDate = Date()
        self.dueDate = dueDate
        self.reminderDate = reminderDate
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    // MARK: - Simple Time Spent Calculation
    var timeSpent: TimeInterval {
        guard let completedDate = completedDate else { return 0 }
        return completedDate.timeIntervalSince(createdDate)
    }
    
    // MARK: - Formatted Time Display
    var formattedTimeSpent: String {
        guard timeSpent > 0 else { return "N/A" }
        
        let hours = Int(timeSpent) / 3600
        let minutes = Int(timeSpent) / 60 % 60
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
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, title, description, priority, category, isCompleted
        case createdDate, dueDate, completedDate, reminderDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        category = try container.decodeIfPresent(TaskCategory.self, forKey: .category) ?? .personal
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        completedDate = try container.decodeIfPresent(Date.self, forKey: .completedDate)
        reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(priority, forKey: .priority)
        try container.encode(category, forKey: .category)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(completedDate, forKey: .completedDate)
        try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
    }
}
