import SwiftUI
import Firebase

@main
struct WashingMachineApp: App {
    
    @StateObject private var authService = AuthService()
    @StateObject private var matchService = MatchService()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(authService)
                    .environmentObject(matchService)
            } else {
                AuthView()
                    .environmentObject(authService)
            }
        }
    }
} 