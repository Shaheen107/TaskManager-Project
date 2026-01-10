import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                DashboardView()
                    .environmentObject(authViewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: authViewModel.isAuthenticated)
    }
}
