import SwiftUI

struct TaskRowView: View {
    let task: TaskItems
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingEditTask = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Completion Button with Animation
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    taskManager.toggleTaskCompletion(task)
                }
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isCompleted ? Color.green : task.priority.color, lineWidth: 2.5)
                        .frame(width: 26, height: 26)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task Content
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Task Meta Info
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // Category Badge
                        MetaBadge(
                            icon: task.category.icon,
                            text: task.category.rawValue,
                            color: task.category.color
                        )
                        
                        // Due Date
                        if let dueDate = task.dueDate {
                            MetaBadge(
                                icon: task.isOverdue ? "exclamationmark.triangle.fill" : "calendar",
                                text: dueDate.formatted(date: .abbreviated, time: .omitted),
                                color: task.isOverdue && !task.isCompleted ? .red : .gray
                            )
                        }
                        
                        // Reminder
                        if task.reminderDate != nil {
                            MetaBadge(
                                icon: "bell.fill",
                                text: "Reminder",
                                color: .orange
                            )
                        }
                        
                        // Time Spent Badge (only for completed tasks)
                        if task.isCompleted && task.timeSpent > 0 {
                            MetaBadge(
                                icon: "clock.fill",
                                text: task.formattedTimeSpent,
                                color: .blue
                            )
                        }
                    }
                }
            }
            
            Spacer()
            
            // Priority Indicator with Glow
            ZStack {
                Circle()
                    .fill(task.priority.color.opacity(0.2))
                    .frame(width: 12, height: 12)
                
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    task.isOverdue && !task.isCompleted ?
                    LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
        .contextMenu {
            Button(action: { showingEditTask = true }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: {
                taskManager.toggleTaskCompletion(task)
            }) {
                Label(
                    task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                    systemImage: task.isCompleted ? "circle" : "checkmark.circle"
                )
            }
            
            Button(role: .destructive, action: {
                taskManager.deleteTask(task)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task)
                .environmentObject(taskManager)
        }
    }
}
