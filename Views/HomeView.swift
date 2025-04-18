import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var matchService: MatchService
    @State private var isRefreshing = false
    @State private var showingMatchDetail = false
    @State private var selectedMatch: Match?
    
    var body: some View {
        NavigationView {
            ScrollView {
                // Pull to refresh
                PullToRefresh(isRefreshing: $isRefreshing) {
                    refreshData()
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome section
                    VStack(alignment: .leading, spacing: 8) {
                        if let user = authService.currentUser {
                            Text("Welcome, \(user.name)")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            HStack {
                                Text("Skill Level: \(user.skillLevel.rawValue)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Rating: \(user.eloRating)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Upcoming matches section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Matches")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        if matchService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if matchService.upcomingMatches.isEmpty {
                            VStack {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 8)
                                
                                Text("No upcoming matches")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    // Navigate to matches tab
                                }) {
                                    Text("Find a match")
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(matchService.upcomingMatches.prefix(3)) { match in
                                MatchCard(match: match) {
                                    selectedMatch = match
                                    showingMatchDetail = true
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Current matches
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Current Matches")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        if matchService.currentMatches.isEmpty {
                            HStack {
                                Spacer()
                                
                                Text("No active matches right now")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .padding()
                                
                                Spacer()
                            }
                        } else {
                            ForEach(matchService.currentMatches) { match in
                                CurrentMatchCard(match: match) {
                                    selectedMatch = match
                                    showingMatchDetail = true
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Stats preview
                    if let user = authService.currentUser {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Stats")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            HStack(spacing: 20) {
                                StatsCard(
                                    title: "Wins",
                                    value: "\(user.wins)",
                                    icon: "trophy.fill",
                                    color: .yellow
                                )
                                
                                StatsCard(
                                    title: "Losses",
                                    value: "\(user.losses)",
                                    icon: "xmark.circle.fill",
                                    color: .red
                                )
                                
                                StatsCard(
                                    title: "Win %",
                                    value: String(format: "%.0f%%", user.winPercentage * 100),
                                    icon: "percent",
                                    color: .blue
                                )
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .background(Color(#colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)))
            .navigationTitle("Home")
            .refreshable {
                refreshData()
            }
        }
        .sheet(isPresented: $showingMatchDetail) {
            if let match = selectedMatch {
                MatchDetailView(match: match)
                    .environmentObject(authService)
                    .environmentObject(matchService)
            }
        }
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        if let userID = authService.currentUser?.id {
            matchService.fetchMatches(for: userID)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
        }
    }
}

struct PullToRefresh: View {
    @Binding var isRefreshing: Bool
    let action: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).minY > 50 {
                // Trigger refresh
                DispatchQueue.main.async {
                    if !isRefreshing {
                        isRefreshing = true
                        action()
                    }
                }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                }
                Spacer()
            }
            .offset(y: max(0, geometry.frame(in: .global).minY / 5))
        }
        .frame(height: isRefreshing ? 40 : 0)
    }
}

struct MatchCard: View {
    let match: Match
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(match.location)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(match.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(match.registeredPlayersCount)/\(match.maxPlayers) players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
            .cornerRadius(10)
        }
    }
}

struct CurrentMatchCard: View {
    let match: Match
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(match.location)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("• Round \(match.currentRound)")
                            .font(.subheadline)
                            .foregroundColor(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                            .fontWeight(.semibold)
                    }
                    
                    Text("Today at \(formattedTime(from: match.date))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Active")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            .padding()
            .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
            .cornerRadius(10)
        }
    }
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .padding(.bottom, 5)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
        .cornerRadius(10)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthService())
            .environmentObject(MatchService())
    }
} 