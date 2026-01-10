import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var taskManager = TaskManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showingAddTask = false
    @State private var selectedTab = 0
    @State private var showingSyncError = false
    @State private var showSyncSuccess = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            homeView
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            NavigationView {
                TaskListView()
                    .environmentObject(taskManager)
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Tasks")
            }
            .tag(1)
            
            NavigationView {
                StatisticsView()
                    .environmentObject(taskManager)
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Stats")
            }
            .tag(2)
            
            NavigationView {
                ProfileView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
                    .environmentObject(taskManager)
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(3)
        }
        .onAppear {
            if let userId = authViewModel.user?.uid {
                taskManager.setupUser(userId: userId, networkMonitor: networkMonitor)
            }
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            NotificationCenter.default.post(name: NSNotification.Name("NetworkStatusChanged"), object: nil)
            
            if isConnected {
                showSyncSuccess = true
                
                Task {
                    await taskManager.syncWhenOnline()
                    
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    withAnimation {
                        showSyncSuccess = false
                    }
                }
            }
        }
        .overlay(
            VStack {
                if taskManager.isSyncing {
                    syncIndicator
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                else if !networkMonitor.isConnected {
                    offlineIndicator
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                else if showSyncSuccess, let lastSync = taskManager.lastSyncTime {
                    syncSuccessIndicator(lastSync)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding(.top, 50)
            .animation(.easeInOut(duration: 0.3), value: taskManager.isSyncing)
            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
            .animation(.easeInOut(duration: 0.3), value: showSyncSuccess)
        )
        .alert("Sync Error", isPresented: $showingSyncError) {
            Button("OK") {
                taskManager.syncError = nil
            }
            Button("Retry") {
                Task {
                    await taskManager.forceSyncNow()
                }
            }
        } message: {
            Text(taskManager.syncError ?? "Unknown error")
        }
        .onChange(of: taskManager.syncError) { error in
            showingSyncError = error != nil
        }
    }
    
    // MARK: - Sync Indicators
    private var syncIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Syncing...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var offlineIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption)
            Text("Offline")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.2))
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func syncSuccessIndicator(_ date: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            Text("Synced just now")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var homeView: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    headerSection
                    
                    if !networkMonitor.isConnected {
                        offlineBanner
                    }
                    
                    quickStatsSection
                    todayTasksSection
                    recentActivitySection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .refreshable {
                if networkMonitor.isConnected {
                    showSyncSuccess = true
                    await taskManager.forceSyncNow()
                    
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation {
                        showSyncSuccess = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(taskManager)
        }
    }
    
    private var offlineBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Working Offline")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Changes will sync when you're back online")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Let's be productive!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: { showingAddTask = true }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.blue.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
    
    private var quickStatsSection: some View {
        let stats = taskManager.statistics
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 14) {
                StatCard(
                    title: "Total",
                    value: "\(stats.totalTasks)",
                    color: .blue,
                    icon: "list.bullet"
                )
                
                StatCard(
                    title: "Done",
                    value: "\(stats.completedTasks)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Pending",
                    value: "\(stats.pendingTasks)",
                    color: .orange,
                    icon: "clock.fill"
                )
            }
        }
    }
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Tasks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !taskManager.todayTasks.isEmpty {
                    Button("View All") {
                        selectedTab = 1
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
            
            if taskManager.todayTasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "All caught up!",
                    subtitle: "No tasks for today"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(taskManager.todayTasks.prefix(3))) { task in
                        TaskRowView(task: task)
                            .environmentObject(taskManager)
                    }
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently Completed")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            if taskManager.completedTasks.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No completed tasks yet",
                    subtitle: "Complete some tasks to see your progress"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(taskManager.completedTasks.prefix(3))) { task in
                        CompletedTaskRowView(task: task)
                    }
                }
            }
        }
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
}
