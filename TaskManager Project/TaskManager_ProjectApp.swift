import SwiftUI
import FirebaseCore
import GoogleSignIn

// MARK: - App Delegate for Google Sign-In
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - Main App Entry Point
@main
struct TaskManager_ProjectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        FirebaseApp.configure()
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    DashboardView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Setup Notifications
    private func setupNotifications() {
        let dailySummaryEnabled = UserDefaults.standard.bool(forKey: "dailySummary")
        if dailySummaryEnabled {
            if let savedTime = UserDefaults.standard.object(forKey: "dailySummaryTime") as? Date {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: savedTime)
                let minute = calendar.component(.minute, from: savedTime)
                NotificationManager.shared.scheduleDailySummary(at: hour, minute: minute)
            }
        }
    }
    
    // MARK: - Handle Scene Phase Changes
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            print("📱 App entered background")
            // Save any pending data if needed
            
        case .active:
            print("📱 App became active")
            // Refresh data if needed
            
        case .inactive:
            print("📱 App became inactive")
            
        @unknown default:
            break
        }
    }
}
