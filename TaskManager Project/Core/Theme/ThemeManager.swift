import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    enum AppTheme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var title: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
        
        var icon: String {
            switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "circle.lefthalf.filled"
            }
        }
        
        var description: String {
            switch self {
            case .light: return "Always light mode"
            case .dark: return "Always dark mode"
            case .system: return "Match device settings"
            }
        }
    }
    
    init() {
        self.currentTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "system") ?? .system
    }
    
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
}
