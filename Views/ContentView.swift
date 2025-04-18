import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var matchService: MatchService
    @State private var selectedTab = 0
    @State private var showingNewMatch = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            MatchesView()
                .tabItem {
                    Label("Matches", systemImage: "sportscourt.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
        .onAppear {
            // Load user's matches when the content view appears
            if let userID = authService.currentUser?.id {
                matchService.fetchMatches(for: userID)
            }
        }
        .onChange(of: authService.currentUser?.id) { newValue in
            if let userID = newValue {
                matchService.fetchMatches(for: userID)
            }
        }
        .overlay(
            ZStack {
                if selectedTab == 1 {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showingNewMatch = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                                    .cornerRadius(30)
                                    .shadow(radius: 5)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
        )
        .sheet(isPresented: $showingNewMatch) {
            CreateMatchView(isPresented: $showingNewMatch)
                .environmentObject(authService)
                .environmentObject(matchService)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService())
            .environmentObject(MatchService())
    }
} 