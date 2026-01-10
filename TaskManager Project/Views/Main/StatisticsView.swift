import SwiftUI
import Charts

// MARK: - Statistics View (FIXED & WORKING)
struct StatisticsView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedTimeRange: TimeRange = .week
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Header Stats
                headerStatsSection
                
                // Time Range Picker (NOW WORKING!)
                timeRangePickerSection
                
                // Completion Rate Chart
                completionRateChart
                
                // Priority Distribution Chart
                priorityDistributionChart
                
                // Weekly Progress Chart
                weeklyProgressChart
                
                // Task Categories
                taskCategoriesSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Stats Section (ENHANCED)
    private var headerStatsSection: some View {
        let stats = taskManager.statistics
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 14) {
                EnhancedStatsCard(
                    title: "Completion",
                    value: stats.completionRateString,
                    subtitle: "Overall progress",
                    color: .green,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                EnhancedStatsCard(
                    title: "Today",
                    value: "\(stats.tasksCompletedToday)",
                    subtitle: "Done today",
                    color: .blue,
                    icon: "checkmark.circle.fill"
                )
                
                EnhancedStatsCard(
                    title: "Active",
                    value: "\(stats.pendingTasks)",
                    subtitle: "Pending",
                    color: .orange,
                    icon: "clock.fill"
                )
                
                EnhancedStatsCard(
                    title: "Total",
                    value: "\(stats.totalTasks)",
                    subtitle: "All tasks",
                    color: .purple,
                    icon: "list.bullet"
                )
            }
        }
    }
    
    // MARK: - Time Range Picker (NOW FUNCTIONAL!)
    private var timeRangePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Completion Rate Chart (FIXED DATA)
    private var completionRateChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Completion Trend")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(dailyCompletionData) { item in
                    LineMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Rate", item.completionRate * 100)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    AreaMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Rate", item.completionRate * 100)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(.caption2)
                    }
                }
                .frame(height: 220)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                )
            } else {
                // Fallback for iOS 15
                SimpleLineChart(data: dailyCompletionData.map { $0.completionRate * 100 })
                    .frame(height: 220)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                    )
            }
            
            // Summary text
            if let avgRate = averageCompletionRate {
                Text("Average: \(Int(avgRate * 100))% completion rate")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Priority Distribution Chart
    private var priorityDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Priority Distribution")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if priorityDistributionData.isEmpty {
                EmptyChartPlaceholder(message: "No tasks to display")
            } else {
                if #available(iOS 17.0, *) {
                    Chart(priorityDistributionData) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(item.priority.color)
                        .cornerRadius(4)
                        .annotation(position: .overlay) {
                            if item.count > 0 {
                                Text("\(item.count)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 220)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                    )
                    
                    // Legend
                    HStack(spacing: 20) {
                        ForEach(priorityDistributionData) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.priority.color)
                                    .frame(width: 10, height: 10)
                                Text(item.priority.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Fallback for iOS 16 and below
                    PriorityDistributionView(data: priorityDistributionData)
                        .frame(height: 220)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        )
                }
            }
        }
    }
    
    // MARK: - Weekly Progress Chart (FIXED!)
    private var weeklyProgressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(selectedTimeRange.title) Progress")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if weeklyProgressData.isEmpty {
                EmptyChartPlaceholder(message: "No activity in this period")
            } else {
                if #available(iOS 16.0, *) {
                    Chart(weeklyProgressData) { item in
                        BarMark(
                            x: .value("Day", item.day),
                            y: .value("Tasks", item.completed)
                        )
                        .foregroundStyle(.green)
                        .position(by: .value("Type", "Completed"))
                        
                        BarMark(
                            x: .value("Day", item.day),
                            y: .value("Tasks", item.created)
                        )
                        .foregroundStyle(.blue.opacity(0.6))
                        .position(by: .value("Type", "Created"))
                    }
                    .chartLegend(position: .top, alignment: .trailing) {
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Circle().fill(.green).frame(width: 8, height: 8)
                                Text("Completed").font(.caption).foregroundColor(.secondary)
                            }
                            HStack(spacing: 6) {
                                Circle().fill(.blue.opacity(0.6)).frame(width: 8, height: 8)
                                Text("Created").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 220)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                    )
                } else {
                    // Fallback for iOS 15
                    SimpleBarChart(data: weeklyProgressData)
                        .frame(height: 220)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                        )
                }
            }
        }
    }
    
    // MARK: - Task Categories Section
    private var taskCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                TaskBreakdownRow(
                    title: "Overdue Tasks",
                    count: taskManager.overdueTasks.count,
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                TaskBreakdownRow(
                    title: "Due Today",
                    count: taskManager.tasks.filter { $0.isDueToday && !$0.isCompleted }.count,
                    color: .orange,
                    icon: "calendar"
                )
                
                TaskBreakdownRow(
                    title: "With Reminders",
                    count: taskManager.tasks.filter { $0.reminderDate != nil && !$0.isCompleted }.count,
                    color: .blue,
                    icon: "bell.fill"
                )
                
                TaskBreakdownRow(
                    title: "Completed This Week",
                    count: completedThisWeekCount,
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
        }
    }
    
    // MARK: - Data Properties (FIXED & WORKING!)
    
    private var numberOfDays: Int {
        switch selectedTimeRange {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
    
    private var dailyCompletionData: [DailyCompletionData] {
        let calendar = Calendar.current
        let today = Date()
        var data: [DailyCompletionData] = []
        
        for i in 0..<numberOfDays {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            // Get tasks created on this day
            let dayTasks = taskManager.tasks.filter { task in
                task.createdDate >= dayStart && task.createdDate < dayEnd
            }
            
            let completedTasks = dayTasks.filter { $0.isCompleted }.count
            let totalTasks = dayTasks.count
            let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
            
            data.append(DailyCompletionData(
                date: dayStart,
                completionRate: completionRate
            ))
        }
        
        return data.reversed()
    }
    
    private var averageCompletionRate: Double? {
        let rates = dailyCompletionData.map { $0.completionRate }
        let nonZeroRates = rates.filter { $0 > 0 }
        
        guard !nonZeroRates.isEmpty else { return nil }
        
        let sum = nonZeroRates.reduce(0, +)
        return sum / Double(nonZeroRates.count)
    }
    
    private var priorityDistributionData: [PriorityData] {
        TaskPriority.allCases.map { priority in
            let count = taskManager.tasks.filter { $0.priority == priority && !$0.isCompleted }.count
            return PriorityData(priority: priority, count: count)
        }.filter { $0.count > 0 }
    }
    
    private var weeklyProgressData: [WeeklyProgressData] {
        let calendar = Calendar.current
        let today = Date()
        var data: [WeeklyProgressData] = []
        
        let daysToShow = min(numberOfDays, 30) // Max 30 days for readability
        
        for i in 0..<daysToShow {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let createdCount = taskManager.tasks.filter { task in
                task.createdDate >= dayStart && task.createdDate < dayEnd
            }.count
            
            let completedCount = taskManager.tasks.filter { task in
                guard let completedDate = task.completedDate else { return false }
                return completedDate >= dayStart && completedDate < dayEnd
            }.count
            
            // Format day name based on time range
            let dayName: String
            switch selectedTimeRange {
            case .week:
                dayName = date.formatted(.dateTime.weekday(.abbreviated))
            case .month:
                dayName = date.formatted(.dateTime.day().month(.abbreviated))
            case .quarter, .year:
                dayName = date.formatted(.dateTime.month(.abbreviated).day())
            }
            
            data.append(WeeklyProgressData(
                day: dayName,
                created: createdCount,
                completed: completedCount
            ))
        }
        
        return data.reversed()
    }
    
    private var completedThisWeekCount: Int {
        let calendar = Calendar.current
        let today = Date()
        
        return taskManager.tasks.filter { task in
            guard let completedDate = task.completedDate else { return false }
            return calendar.isDate(completedDate, equalTo: today, toGranularity: .weekOfYear)
        }.count
    }
}

// MARK: - Enhanced Stats Card
struct EnhancedStatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Empty Chart Placeholder
struct EmptyChartPlaceholder: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Supporting Views (Keep existing)


// MARK: - Data Models
struct DailyCompletionData: Identifiable {
    let id = UUID()
    let date: Date
    let completionRate: Double
}

struct PriorityData: Identifiable {
    let id = UUID()
    let priority: TaskPriority
    let count: Int
}

struct WeeklyProgressData: Identifiable {
    let id = UUID()
    let day: String
    let created: Int
    let completed: Int
}

enum TimeRange: CaseIterable {
    case week, month, quarter, year
    
    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
}

// MARK: - Fallback Charts (Keep existing SimpleLineChart, SimpleBarChart, PriorityDistributionView)
struct SimpleLineChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let stepY = geometry.size.height / 4
                    for i in 0...4 {
                        let y = stepY * CGFloat(i)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                
                Path { path in
                    guard !data.isEmpty else { return }
                    
                    let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
                    let maxValue = 100.0
                    
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geometry.size.height - (CGFloat(value) / CGFloat(maxValue)) * geometry.size.height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
                    let maxValue = 100.0
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - (CGFloat(value) / CGFloat(maxValue)) * geometry.size.height
                    
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

struct SimpleBarChart: View {
    let data: [WeeklyProgressData]
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.map { max($0.created, $0.completed) }.max() ?? 1, 1)
            let barWidth = (geometry.size.width / CGFloat(data.count)) * 0.7
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 4) {
                        HStack(spacing: 2) {
                            // Completed
                            Rectangle()
                                .fill(.green)
                                .frame(
                                    width: barWidth / 2,
                                    height: max(CGFloat(item.completed) / CGFloat(maxValue) * (geometry.size.height - 30), 4)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                            
                            // Created
                            Rectangle()
                                .fill(.blue.opacity(0.6))
                                .frame(
                                    width: barWidth / 2,
                                    height: max(CGFloat(item.created) / CGFloat(maxValue) * (geometry.size.height - 30), 4)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        
                        Text(item.day)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

struct PriorityDistributionView: View {
    let data: [PriorityData]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(data) { item in
                let total = data.reduce(0) { $0 + $1.count }
                let percentage = total > 0 ? Double(item.count) / Double(total) : 0
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.priority.color)
                                .frame(width: 12, height: 12)
                            
                            Text(item.priority.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(item.priority.color)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            
                            Rectangle()
                                .fill(item.priority.color)
                                .frame(
                                    width: geometry.size.width * CGFloat(percentage),
                                    height: 10
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .animation(.easeInOut(duration: 0.8), value: percentage)
                        }
                    }
                    .frame(height: 10)
                }
            }
        }
    }
}
