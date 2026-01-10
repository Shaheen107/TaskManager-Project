import Foundation
import SwiftUI
import UserNotifications
import Firebase
import FirebaseFirestore

@MainActor
class TaskManager: ObservableObject {
    @Published var tasks: [TaskItems] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncError: String?
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = AppConstants.UserDefaultsKeys.savedTasks
    private let lastSyncKey = AppConstants.UserDefaultsKeys.lastSync
    private let db = Firestore.firestore()
    private var userId: String?
    private var listener: ListenerRegistration?
    private var pendingSyncTasks: Set<UUID> = [] // Tasks waiting to sync
    
    // Network monitor
    private var networkMonitor: NetworkMonitor?
    
    // Update TaskManager init method

    init() {
        loadTasksFromLocal()
        loadLastSyncTime()
        requestNotificationPermission()
        
        // Load notification settings and schedule if enabled
        let dailySummaryEnabled = userDefaults.bool(forKey: AppConstants.UserDefaultsKeys.dailySummaryEnabled)
        if dailySummaryEnabled {
            if let savedTime = userDefaults.object(forKey: AppConstants.UserDefaultsKeys.dailySummaryTime) as? Date {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: savedTime)
                let minute = calendar.component(.minute, from: savedTime)
                NotificationManager.shared.scheduleDailySummary(at: hour, minute: minute)
            }
        }
    }
    
    // MARK: - Setup User with Network Monitoring
    func setupUser(userId: String, networkMonitor: NetworkMonitor) {
        self.userId = userId
        self.networkMonitor = networkMonitor
        
        // Start listening to network changes
        setupNetworkObserver()
        
        // Initial sync if connected
        if networkMonitor.isConnected {
            syncFromFirebase()
        }
    }
    
    // MARK: - Network Observer
    private func setupNetworkObserver() {
        // This will be called whenever network status changes
        Task {
            guard let networkMonitor = networkMonitor else { return }
            
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("NetworkStatusChanged")).map({ _ in () }) {
                if networkMonitor.isConnected {
                    print("📡 Network connected - Starting sync...")
                    await syncWhenOnline()
                } else {
                    print("📡 Network disconnected - Working offline")
                }
            }
        }
    }
    
    // MARK: - Sync When Online
    func syncWhenOnline() async {
        guard let networkMonitor = networkMonitor, networkMonitor.isConnected else {
            print("⚠️ No network connection available")
            return
        }
        
        print("🔄 Syncing pending changes...")
        
        // Upload pending local changes first
        await uploadPendingChanges()
        
        // Then fetch latest from Firebase
        syncFromFirebase()
    }
    
    // MARK: - Upload Pending Changes
    private func uploadPendingChanges() async {
        guard !pendingSyncTasks.isEmpty else { return }
        
        let tasksToSync = tasks.filter { pendingSyncTasks.contains($0.id) }
        
        for task in tasksToSync {
            saveTaskToFirebase(task)
        }
        
        // Clear pending sync after successful upload
        pendingSyncTasks.removeAll()
        savePendingSyncTasks()
    }
    
    // MARK: - Local Storage (UserDefaults) - Works Offline
    private func saveTasksToLocal() {
        do {
            let data = try JSONEncoder().encode(tasks)
            userDefaults.set(data, forKey: tasksKey)
        } catch {
            print("❌ Failed to save tasks locally: \(error)")
        }
    }
    
    private func loadTasksFromLocal() {
        guard let data = userDefaults.data(forKey: tasksKey) else {
            return
        }
        
        do {
            tasks = try JSONDecoder().decode([TaskItems].self, from: data)
            print("✅ Loaded \(tasks.count) tasks from local storage")
        } catch {
            print("❌ Failed to load tasks from local: \(error)")
            tasks = []
        }
    }
    
    // MARK: - Last Sync Time
    private func saveLastSyncTime() {
        lastSyncTime = Date()
        userDefaults.set(lastSyncTime, forKey: lastSyncKey)
    }
    
    private func loadLastSyncTime() {
        lastSyncTime = userDefaults.object(forKey: lastSyncKey) as? Date
    }
    
    // MARK: - Pending Sync Tasks
    private func savePendingSyncTasks() {
        let pendingIds = Array(pendingSyncTasks).map { $0.uuidString }
        userDefaults.set(pendingIds, forKey: "pending_sync_tasks")
    }
    
    private func loadPendingSyncTasks() {
        if let pendingIds = userDefaults.array(forKey: "pending_sync_tasks") as? [String] {
            pendingSyncTasks = Set(pendingIds.compactMap { UUID(uuidString: $0) })
        }
    }
    
    // MARK: - Firebase Sync with Real-time Listener
    func syncFromFirebase() {
        guard let userId = userId else {
            print("⚠️ No user ID available for sync")
            return
        }
        
        // Remove old listener if exists
        listener?.remove()
        
        isSyncing = true
        syncError = nil
        
        // Real-time listener
        listener = db.collection(AppConstants.usersCollection)
  .document(userId)
  .collection(AppConstants.tasksCollection)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching tasks from Firebase: \(error.localizedDescription)")
                    self.syncError = error.localizedDescription
                    self.isSyncing = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.isSyncing = false
                    return
                }
                
                print("📥 Received \(documents.count) tasks from Firebase")
                
                // Convert Firestore documents to TaskItems
                var firebaseTasks: [TaskItems] = []
                
                for document in documents {
                    if let task = self.decodeTaskFromFirestore(document.data(), id: document.documentID) {
                        firebaseTasks.append(task)
                    }
                }
                
                // Merge with local tasks using improved logic
                self.mergeTasks(firebaseTasks)
                self.saveTasksToLocal()
                self.saveLastSyncTime()
                self.isSyncing = false
                
                print("✅ Sync completed successfully")
            }
    }
    
    // MARK: - Save Task to Firebase
    private func saveTaskToFirebase(_ task: TaskItems) {
        guard let userId = userId else {
            // Add to pending sync if no user ID
            pendingSyncTasks.insert(task.id)
            savePendingSyncTasks()
            return
        }
        
        guard let networkMonitor = networkMonitor, networkMonitor.isConnected else {
            // Add to pending sync if offline
            print("📴 Offline - Task \(task.title) added to pending sync")
            pendingSyncTasks.insert(task.id)
            savePendingSyncTasks()
            return
        }
        
        let taskData = encodeTaskForFirestore(task)
        
        db.collection("users").document(userId).collection("tasks")
            .document(task.id.uuidString)
            .setData(taskData, merge: true) { [weak self] error in
                if let error = error {
                    print("❌ Error saving task to Firebase: \(error.localizedDescription)")
                    // Add to pending sync on error
                    self?.pendingSyncTasks.insert(task.id)
                    self?.savePendingSyncTasks()
                } else {
                    print("✅ Task '\(task.title)' saved to Firebase")
                    // Remove from pending sync on success
                    self?.pendingSyncTasks.remove(task.id)
                    self?.savePendingSyncTasks()
                }
            }
    }
    
    // MARK: - Delete Task from Firebase
    private func deleteTaskFromFirebase(_ taskId: String) {
        guard let userId = userId else { return }
        
        guard let networkMonitor = networkMonitor, networkMonitor.isConnected else {
            print("📴 Offline - Task deletion will sync later")
            return
        }
        
        db.collection("users").document(userId).collection("tasks")
            .document(taskId)
            .delete { error in
                if let error = error {
                    print("❌ Error deleting task from Firebase: \(error.localizedDescription)")
                } else {
                    print("✅ Task deleted from Firebase")
                }
            }
    }
    
    // MARK: - Firestore Encoding/Decoding
    private func encodeTaskForFirestore(_ task: TaskItems) -> [String: Any] {
        var data: [String: Any] = [
            "id": task.id.uuidString,
            "title": task.title,
            "description": task.description,
            "priority": task.priority.rawValue,
            "category": task.category.rawValue,
            "isCompleted": task.isCompleted,
            "createdDate": Timestamp(date: task.createdDate),
            "lastModified": Timestamp(date: Date()) // Add last modified timestamp
        ]
        
        if let dueDate = task.dueDate {
            data["dueDate"] = Timestamp(date: dueDate)
        }
        
        if let completedDate = task.completedDate {
            data["completedDate"] = Timestamp(date: completedDate)
        }
        
        if let reminderDate = task.reminderDate {
            data["reminderDate"] = Timestamp(date: reminderDate)
        }
        
        return data
    }
    
    private func decodeTaskFromFirestore(_ data: [String: Any], id: String) -> TaskItems? {
        guard
            let title = data["title"] as? String,
            let description = data["description"] as? String,
            let priorityString = data["priority"] as? String,
            let priority = TaskPriority(rawValue: priorityString),
            let categoryString = data["category"] as? String,
            let category = TaskCategory(rawValue: categoryString),
            let isCompleted = data["isCompleted"] as? Bool,
            let createdTimestamp = data["createdDate"] as? Timestamp
        else {
            print("⚠️ Failed to decode task from Firestore")
            return nil
        }
        
        var task = TaskItems(
            title: title,
            description: description,
            priority: priority,
            category: category,
            dueDate: nil,
            reminderDate: nil
        )
        
        task.id = UUID(uuidString: id) ?? UUID()
        task.isCompleted = isCompleted
        task.createdDate = createdTimestamp.dateValue()
        
        if let dueTimestamp = data["dueDate"] as? Timestamp {
            task.dueDate = dueTimestamp.dateValue()
        }
        
        if let completedTimestamp = data["completedDate"] as? Timestamp {
            task.completedDate = completedTimestamp.dateValue()
        }
        
        if let reminderTimestamp = data["reminderDate"] as? Timestamp {
            task.reminderDate = reminderTimestamp.dateValue()
        }
        
        return task
    }
    
    // MARK: - Improved Task Merge Logic with Conflict Resolution
    private func mergeTasks(_ firebaseTasks: [TaskItems]) {
        var mergedTasks: [UUID: TaskItems] = [:]
        var localTasksDict: [UUID: TaskItems] = [:]
        
        // Create dictionary from local tasks
        for task in tasks {
            localTasksDict[task.id] = task
        }
        
        // Process Firebase tasks (Firebase has priority in conflicts)
        for fbTask in firebaseTasks {
            mergedTasks[fbTask.id] = fbTask
        }
        
        // Add local-only tasks (not in Firebase yet)
        for (id, localTask) in localTasksDict {
            if mergedTasks[id] == nil {
                // This task exists only locally - add it and mark for upload
                mergedTasks[id] = localTask
                pendingSyncTasks.insert(id)
                
                // Upload to Firebase if online
                if let networkMonitor = networkMonitor, networkMonitor.isConnected {
                    saveTaskToFirebase(localTask)
                }
            }
        }
        
        // Update tasks array
        tasks = Array(mergedTasks.values).sorted { $0.createdDate > $1.createdDate }
        
        savePendingSyncTasks()
        
        print("🔄 Merged tasks: \(tasks.count) total, \(pendingSyncTasks.count) pending sync")
    }
    
    // MARK: - Task Operations (Updated with Network Awareness)
    func addTask(_ task: TaskItems) {
        tasks.append(task)
        saveTasksToLocal()
        
        // Try to sync to Firebase
        saveTaskToFirebase(task)
        
        // Schedule notification if reminder is set
        if let reminderDate = task.reminderDate {
            scheduleNotification(for: task, at: reminderDate)
        }
    }
    
    func updateTask(_ task: TaskItems) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        // Cancel existing notification
        cancelNotification(for: task.id.uuidString)
        
        tasks[index] = task
        saveTasksToLocal()
        
        // Try to sync to Firebase
        saveTaskToFirebase(task)
        
        // Schedule new notification if reminder is set
        if let reminderDate = task.reminderDate {
            scheduleNotification(for: task, at: reminderDate)
        }
    }
    
    func deleteTask(_ task: TaskItems) {
        // Cancel notification
        cancelNotification(for: task.id.uuidString)
        
        tasks.removeAll { $0.id == task.id }
        saveTasksToLocal()
        
        // Remove from pending sync
        pendingSyncTasks.remove(task.id)
        savePendingSyncTasks()
        
        // Delete from Firebase
        deleteTaskFromFirebase(task.id.uuidString)
    }
    
    func toggleTaskCompletion(_ task: TaskItems) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        tasks[index].isCompleted.toggle()
        tasks[index].completedDate = tasks[index].isCompleted ? Date() : nil
        
        // Cancel notification if task is completed
        if tasks[index].isCompleted {
            cancelNotification(for: task.id.uuidString)
        }
        
        saveTasksToLocal()
        
        // Sync to Firebase
        saveTaskToFirebase(tasks[index])
    }
    
    // MARK: - Manual Sync Trigger
    func forceSyncNow() async {
        guard let networkMonitor = networkMonitor else { return }
        
        if networkMonitor.isConnected {
            await syncWhenOnline()
        } else {
            syncError = "No internet connection"
        }
    }
    
    // MARK: - Task Filtering & Statistics (Keep as is)
    var incompleteTasks: [TaskItems] {
        tasks.filter { !$0.isCompleted }
            .sorted { $0.priority.sortOrder > $1.priority.sortOrder }
    }
    
    var completedTasks: [TaskItems] {
        tasks.filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? Date()) > ($1.completedDate ?? Date()) }
    }
    
    var todayTasks: [TaskItems] {
        tasks.filter { task in
            Calendar.current.isDateInToday(task.createdDate) ||
            task.isDueToday ||
            (task.completedDate != nil && Calendar.current.isDateInToday(task.completedDate!))
        }
    }
    
    var overdueTasks: [TaskItems] {
        tasks.filter { $0.isOverdue }
    }
    
    var statistics: TaskStatistics {
        let total = tasks.count
        let completed = completedTasks.count
        let pending = incompleteTasks.count
        let overdue = overdueTasks.count
        let today = todayTasks.count
        let todayCompleted = tasks.filter { task in
            task.isCompleted && task.completedDate != nil &&
            Calendar.current.isDateInToday(task.completedDate!)
        }.count
        
        let completionRate = total > 0 ? Double(completed) / Double(total) : 0.0
        
        // Calculate average completion time
        let completedWithTime = tasks.filter { $0.isCompleted && $0.completedDate != nil }
        let totalTime = completedWithTime.reduce(0.0) { $0 + $1.timeSpent }
        let averageTime = completedWithTime.count > 0 ? totalTime / Double(completedWithTime.count) : 0
        
        return TaskStatistics(
            totalTasks: total,
            completedTasks: completed,
            pendingTasks: pending,
            overdueTasks: overdue,
            todayTasks: today,
            completionRate: completionRate,
            tasksCompletedToday: todayCompleted,
            averageCompletionTime: averageTime
        )
    }
    
    // MARK: - Notifications (Keep as is)
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleNotification(for task: TaskItems, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    
    

    // MARK: - Manual Backup to Firebase
    // MARK: - Manual Backup to Firebase
    func manualBackupToFirebase() async {
        guard let userId = userId else {
            await MainActor.run {
                syncError = "No user logged in"
            }
            return
        }
        
        await MainActor.run {
            isSyncing = true
        }
        
        print("🔄 Starting manual backup of \(tasks.count) tasks...")
        
        // Upload all tasks one by one
        for task in tasks {
            saveTaskToFirebase(task)
        }
        
        // Wait for uploads to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            saveLastSyncTime()
            isSyncing = false
            syncError = nil
        }
        
        print("✅ Manual backup completed successfully")
    }

    // MARK: - Manual Restore from Firebase
    func manualRestoreFromFirebase() {
        guard let userId = userId else {
            syncError = "No user logged in"
            return
        }
        
        isSyncing = true
        print("🔄 Starting manual restore...")
        
        // Fetch all tasks from Firebase
        db.collection("users").document(userId).collection("tasks")
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Restore error: \(error.localizedDescription)")
                    self.syncError = "Failed to restore: \(error.localizedDescription)"
                    self.isSyncing = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.syncError = "No data found in cloud"
                    self.isSyncing = false
                    return
                }
                
                print("📥 Restoring \(documents.count) tasks from cloud...")
                
                // Clear local tasks
                self.tasks.removeAll()
                
                // Add all tasks from Firebase
                var restoredTasks: [TaskItems] = []
                for document in documents {
                    if let task = self.decodeTaskFromFirestore(document.data(), id: document.documentID) {
                        restoredTasks.append(task)
                    }
                }
                
                self.tasks = restoredTasks
                
                // Save to local storage
                self.saveTasksToLocal()
                self.saveLastSyncTime()
                self.isSyncing = false
                self.syncError = nil
                
                print("✅ Restore completed: \(self.tasks.count) tasks restored")
            }
    }
    
    
    

    // MARK: - Clear All Data (for logout)
    func clearAllData() {
        print("🗑️ Clearing all local data...")
        
        // Stop Firebase listener
        listener?.remove()
        listener = nil
        
        // Clear tasks array
        tasks.removeAll()
        
        // Clear pending sync tasks
        pendingSyncTasks.removeAll()
        
        // Clear UserDefaults
        userDefaults.removeObject(forKey: tasksKey)
        userDefaults.removeObject(forKey: lastSyncKey)
        userDefaults.removeObject(forKey: "pending_sync_tasks")
        
        // Reset sync time
        lastSyncTime = nil
        
        // Reset user ID
        userId = nil
        
        // Reset network monitor
        networkMonitor = nil
        
        print("✅ All data cleared successfully")
    }
    
    
    
    private func cancelNotification(for taskId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskId])
    }
    
    // Clean up listener
    deinit {
        listener?.remove()
    }
}
