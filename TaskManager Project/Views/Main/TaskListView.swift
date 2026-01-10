import SwiftUI

// MARK: - Task List View
struct TaskListView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingAddTask = false
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchSection
            
            // Filter Tabs
            filterSection
            
            // Task List
            taskListSection
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(taskManager)
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            TextField("Search tasks...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        title: filter.title,
                        count: getTaskCount(for: filter),
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    private var taskListSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredTasks) { task in
                    TaskRowView(task: task)
                        .environmentObject(taskManager)
                }
                
                if filteredTasks.isEmpty {
                    EmptyTaskListView(filter: selectedFilter, searchText: searchText)
                        .padding(.top, 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    private var filteredTasks: [TaskItems] {
        let tasks = getFilteredTasks()
        
        if searchText.isEmpty {
            return tasks
        } else {
            return tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func getFilteredTasks() -> [TaskItems] {
        switch selectedFilter {
        case .all:
            return taskManager.tasks.sorted { $0.createdDate > $1.createdDate }
        case .pending:
            return taskManager.incompleteTasks
        case .completed:
            return taskManager.completedTasks
        case .today:
            return taskManager.todayTasks
        case .overdue:
            return taskManager.overdueTasks
        case .high:
            return taskManager.tasks.filter { $0.priority == .high }
        case .medium:
            return taskManager.tasks.filter { $0.priority == .medium }
        case .low:
            return taskManager.tasks.filter { $0.priority == .low }
        }
    }
    
    private func getTaskCount(for filter: TaskFilter) -> Int {
        switch filter {
        case .all: return taskManager.tasks.count
        case .pending: return taskManager.incompleteTasks.count
        case .completed: return taskManager.completedTasks.count
        case .today: return taskManager.todayTasks.count
        case .overdue: return taskManager.overdueTasks.count
        case .high: return taskManager.tasks.filter { $0.priority == .high }.count
        case .medium: return taskManager.tasks.filter { $0.priority == .medium }.count
        case .low: return taskManager.tasks.filter { $0.priority == .low }.count
        }
    }
}

// MARK: - Task Filter Enum
enum TaskFilter: CaseIterable {
    case all, pending, completed, today, overdue, high, medium, low
    
    var title: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .today: return "Today"
        case .overdue: return "Overdue"
        case .high: return "High Priority"
        case .medium: return "Medium Priority"
        case .low: return "Low Priority"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .pending: return .orange
        case .completed: return .green
        case .today: return .purple
        case .overdue: return .red
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.3)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Task List View
struct EmptyTaskListView: View {
    let filter: TaskFilter
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(emptyStateSubtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        
        switch filter {
        case .all: return "tray"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .today: return "calendar"
        case .overdue: return "exclamationmark.triangle"
        case .high, .medium, .low: return "flag"
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }
        
        switch filter {
        case .all: return "No Tasks Yet"
        case .pending: return "All Caught Up!"
        case .completed: return "No Completed Tasks"
        case .today: return "Nothing for Today"
        case .overdue: return "No Overdue Tasks"
        case .high, .medium, .low: return "No \(filter.title) Tasks"
        }
    }
    
    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or browse all tasks"
        }
        
        switch filter {
        case .all: return "Create your first task to get started"
        case .pending: return "Great job! No pending tasks"
        case .completed: return "Complete some tasks to see them here"
        case .today: return "Enjoy your free day!"
        case .overdue: return "You're on track! No overdue tasks"
        case .high, .medium, .low: return "No tasks with \(filter.title.lowercased()) found"
        }
    }
}
