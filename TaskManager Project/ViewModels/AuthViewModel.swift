import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var isAuthenticated: Bool = false
    
    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
    }
    
    // MARK: - Email/Password
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            withAnimation(.easeInOut(duration: 0.5)) {
                self.user = result.user
                self.isAuthenticated = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            withAnimation(.easeInOut(duration: 0.5)) {
                self.user = result.user
                self.isAuthenticated = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out with Data Clearing
    func signOut(taskManager: TaskManager? = nil) {
        do {
            // Clear all local task data BEFORE signing out
            taskManager?.clearAllData()
            
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                self.user = nil
                self.isAuthenticated = false
            }
            
            print("✅ User signed out successfully")
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Sign out error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = ""
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let rootVC = await UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else {
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            withAnimation(.easeInOut(duration: 0.5)) {
                self.user = authResult.user
                self.isAuthenticated = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
