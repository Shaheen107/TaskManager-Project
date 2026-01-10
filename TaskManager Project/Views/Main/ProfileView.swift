import SwiftUI
import UserNotifications

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSignOutAlert = false
    @State private var showingExportOptions = false
    @State private var exportMessage = ""
    @State private var showExportMessage = false
    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var showBackupSuccess = false
    @State private var showRestoreSuccess = false
    @State private var showBackupError = false
    @State private var showRestoreError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            // Profile Header
            profileHeaderSection
            
            // App Settings
            appSettingsSection
            
            // Data Management
            dataManagementSection
            
            // Account Actions
            accountActionsSection
            
            // App Info
            appInfoSection
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut(taskManager: taskManager)
            }
        } message: {
            Text("Are you sure you want to sign out? All local data will be cleared.")
        }
        .confirmationDialog("Export Data", isPresented: $showingExportOptions) {
            Button("Export as CSV") {
                exportAsCSV()
            }
            Button("Export as PDF") {
                exportAsPDF()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose export format")
        }
        .alert("Export Status", isPresented: $showExportMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportMessage)
        }
        .alert("Backup Successful", isPresented: $showBackupSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All \(taskManager.tasks.count) tasks have been backed up to the cloud successfully!")
        }
        .alert("Restore Successful", isPresented: $showRestoreSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your tasks have been restored from the cloud successfully!")
        }
        .alert("Error", isPresented: $showBackupError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                performBackup()
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Error", isPresented: $showRestoreError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                performRestore()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                // Profile Avatar
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(authViewModel.user?.email?.prefix(1).uppercased() ?? "U"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.user?.displayName ?? "User")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(authViewModel.user?.email ?? "No email")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Text("Verified Account")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - App Settings Section (COMPLETELY REDESIGNED)
    private var appSettingsSection: some View {
        Section {
            // Theme Options - Card Style
            VStack(spacing: 0) {
                ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                    ThemeOptionCard(
                        theme: theme,
                        isSelected: themeManager.currentTheme == theme,
                        action: {
                            themeManager.setTheme(theme)
                        }
                    )
                    
                    if theme != ThemeManager.AppTheme.allCases.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Notifications
            NavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    Text("Notifications")
                        .font(.system(size: 16))
                }
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Choose your preferred color theme")
                .font(.caption)
        }
    }
    
    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        Section {
            // Export Data
            Button(action: { showingExportOptions = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Export Data")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Backup to Cloud
            Button(action: { performBackup() }) {
                HStack {
                    if isBackingUp {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 24)
                    } else {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .frame(width: 24)
                    }
                    
                    Text("Backup to Cloud")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isBackingUp {
                        Text("Uploading...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(isBackingUp || isRestoring)
            
            // Restore from Cloud
            Button(action: { performRestore() }) {
                HStack {
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 24)
                    } else {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                            .frame(width: 24)
                    }
                    
                    Text("Restore from Cloud")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isRestoring {
                        Text("Downloading...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(isBackingUp || isRestoring)
            
            // Last Sync Info
            if let lastSync = taskManager.lastSyncTime {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    Text("Last Synced")
                        .font(.system(size: 16))
                    
                    Spacer()
                    
                    Text(timeAgo(from: lastSync))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Data Management")
        } footer: {
            Text("Backup stores all your tasks in the cloud. Restore downloads the latest backup and replaces your local data.")
                .font(.caption)
        }
    }
    
    // MARK: - Account Actions Section
    private var accountActionsSection: some View {
        Section("Account") {
            // Sign Out
            Button(action: { showingSignOutAlert = true }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Sign Out")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        Section("About") {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Text("Version")
                    .font(.system(size: 16))
                
                Spacer()
                
                Text("1.0.0")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Text("Total Tasks")
                    .font(.system(size: 16))
                
                Spacer()
                
                Text("\(taskManager.tasks.count)")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Export Actions
    private func exportAsCSV() {
        if let url = ExportManager.exportToCSV(tasks: taskManager.tasks) {
            shareFile(url: url)
            exportMessage = "CSV file exported successfully!"
        } else {
            exportMessage = "Failed to export CSV file."
        }
        showExportMessage = true
    }
    
    private func exportAsPDF() {
        let statistics = taskManager.statistics
        if let url = ExportManager.exportToPDF(tasks: taskManager.tasks, statistics: statistics) {
            shareFile(url: url)
            exportMessage = "PDF report generated successfully!"
        } else {
            exportMessage = "Failed to generate PDF report."
        }
        showExportMessage = true
    }
    
    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Backup/Restore Actions
    private func performBackup() {
        guard taskManager.tasks.count > 0 else {
            errorMessage = "No tasks to backup."
            showBackupError = true
            return
        }
        
        isBackingUp = true
        
        Task {
            do {
                await taskManager.manualBackupToFirebase()
                
                try await Task.sleep(nanoseconds: 1_500_000_000)
                
                await MainActor.run {
                    isBackingUp = false
                    showBackupSuccess = true
                }
            } catch {
                await MainActor.run {
                    isBackingUp = false
                    errorMessage = "Backup failed. Please check your internet connection and try again."
                    showBackupError = true
                }
            }
        }
    }
    
    private func performRestore() {
        isRestoring = true
        
        Task {
            await MainActor.run {
                taskManager.manualRestoreFromFirebase()
            }
            
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                isRestoring = false
                
                if taskManager.syncError == nil {
                    showRestoreSuccess = true
                } else {
                    errorMessage = taskManager.syncError ?? "Restore failed. Please check your internet connection and try again."
                    showRestoreError = true
                    taskManager.syncError = nil
                }
            }
        }
    }
    
    // MARK: - Helper
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Theme Option Card Component (BRAND NEW DESIGN)
struct ThemeOptionCard: View {
    let theme: ThemeManager.AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: theme.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                
                // Theme Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    
                    Text(theme.description)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.accentColor)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconBackgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        }
        return Color.secondary.opacity(0.1)
    }
    
    private var iconColor: Color {
        if isSelected {
            return Color.accentColor
        }
        return Color.secondary
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @State private var notificationsEnabled = true
    @State private var reminderNotifications = true
    @State private var dailySummary = false
    @State private var taskDeadlines = true
    @State private var dailySummaryTime = Date()
    @State private var showingTimeChanged = false
    
    var body: some View {
        List {
            Section("Notification Preferences") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { value in
                        if value {
                            requestNotificationPermission()
                        } else {
                            NotificationManager.shared.cancelDailySummary()
                        }
                    }
                
                if notificationsEnabled {
                    Toggle("Task Reminders", isOn: $reminderNotifications)
                        .onChange(of: reminderNotifications) { _ in
                            saveNotificationSettings()
                        }
                    
                    Toggle("Daily Summary", isOn: $dailySummary)
                        .onChange(of: dailySummary) { value in
                            if value {
                                scheduleDailySummary()
                            } else {
                                NotificationManager.shared.cancelDailySummary()
                            }
                            saveNotificationSettings()
                        }
                    
                    Toggle("Task Deadlines", isOn: $taskDeadlines)
                        .onChange(of: taskDeadlines) { _ in
                            saveNotificationSettings()
                        }
                }
            }
            
            if notificationsEnabled && dailySummary {
                Section("Daily Summary Settings") {
                    DatePicker("Notification Time", selection: $dailySummaryTime, displayedComponents: .hourAndMinute)
                        .onChange(of: dailySummaryTime) { _ in
                            scheduleDailySummary()
                            showingTimeChanged = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showingTimeChanged = false
                            }
                        }
                    
                    if showingTimeChanged {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Daily summary time updated")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: showingTimeChanged)
            }
            
            Section {
                Button("Open Notification Settings") {
                    openNotificationSettings()
                }
            } footer: {
                Text("You can manage detailed notification settings in your device's Settings app.")
                    .font(.caption)
            }
            
            if notificationsEnabled {
                Section("About Notifications") {
                    VStack(alignment: .leading, spacing: 12) {
                        NotificationInfoRow(
                            icon: "bell.badge",
                            title: "Task Reminders",
                            description: "Get notified when tasks are due"
                        )
                        
                        Divider()
                        
                        NotificationInfoRow(
                            icon: "chart.bar.doc.horizontal",
                            title: "Daily Summary",
                            description: "Daily productivity overview at your chosen time"
                        )
                        
                        Divider()
                        
                        NotificationInfoRow(
                            icon: "clock.badge.exclamationmark",
                            title: "Task Deadlines",
                            description: "Alerts for approaching deadlines"
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationStatus()
            loadNotificationSettings()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    notificationsEnabled = false
                }
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func scheduleDailySummary() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dailySummaryTime)
        let minute = calendar.component(.minute, from: dailySummaryTime)
        
        NotificationManager.shared.scheduleDailySummary(at: hour, minute: minute)
    }
    
    private func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func saveNotificationSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(reminderNotifications, forKey: "reminderNotifications")
        UserDefaults.standard.set(dailySummary, forKey: "dailySummary")
        UserDefaults.standard.set(taskDeadlines, forKey: "taskDeadlines")
        UserDefaults.standard.set(dailySummaryTime, forKey: "dailySummaryTime")
    }
    
    private func loadNotificationSettings() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        reminderNotifications = UserDefaults.standard.bool(forKey: "reminderNotifications")
        dailySummary = UserDefaults.standard.bool(forKey: "dailySummary")
        taskDeadlines = UserDefaults.standard.bool(forKey: "taskDeadlines")
        
        if let savedTime = UserDefaults.standard.object(forKey: "dailySummaryTime") as? Date {
            dailySummaryTime = savedTime
        }
        
        if dailySummary {
            scheduleDailySummary()
        }
    }
}

// MARK: - Notification Info Row
struct NotificationInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
