import SwiftUI

struct EditTaskView: View {
    let task: TaskItems
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority = TaskPriority.medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasReminder = false
    @State private var reminderDate = Date()
    @State private var isCompleted = false
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section("Task Details") {
                    TextField("Task title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Status Section
                Section("Status") {
                    Toggle("Completed", isOn: $isCompleted)
                    
                    if let createdDate = task.createdDate as Date? {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(createdDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let completedDate = task.completedDate {
                        HStack {
                            Text("Completed")
                            Spacer()
                            Text(completedDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Priority Section
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Due Date Section
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        
                        if task.isOverdue && !isCompleted {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("This task is overdue")
                                    .foregroundColor(.red)
                            }
                            .font(.caption)
                        }
                    }
                }
                
                // Reminder Section
                Section("Reminder") {
                    Toggle("Set reminder", isOn: $hasReminder)
                    
                    if hasReminder {
                        DatePicker(
                            "Reminder time",
                            selection: $reminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        
                        Text("You'll receive a notification at this time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive, action: deleteTask) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Task")
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadTaskData()
            }
        }
    }
    
    private func loadTaskData() {
        title = task.title
        description = task.description
        priority = task.priority
        isCompleted = task.isCompleted
        
        if let taskDueDate = task.dueDate {
            hasDueDate = true
            dueDate = taskDueDate
        }
        
        if let taskReminderDate = task.reminderDate {
            hasReminder = true
            reminderDate = taskReminderDate
        } else {
            reminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }
    }
    
    private func saveChanges() {
        var updatedTask = task
        updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.priority = priority
        updatedTask.isCompleted = isCompleted
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.reminderDate = hasReminder ? reminderDate : nil
        
        // Update completion date
        if isCompleted && !task.isCompleted {
            updatedTask.completedDate = Date()
        } else if !isCompleted && task.isCompleted {
            updatedTask.completedDate = nil
        }
        
        taskManager.updateTask(updatedTask)
        dismiss()
    }
    
    private func deleteTask() {
        taskManager.deleteTask(task)
        dismiss()
    }
}
