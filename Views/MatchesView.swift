import SwiftUI

struct MatchesView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var matchService: MatchService
    
    @State private var selectedFilter = MatchFilter.upcoming
    @State private var searchText = ""
    @State private var showingMatchDetail = false
    @State private var selectedMatch: Match?
    
    enum MatchFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case current = "Current"
        case past = "Past"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Filter Buttons
                filterButtons
                
                // Match List
                matchList
            }
            .background(Color(#colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)))
            .navigationTitle("Matches")
            .refreshable {
                if let userID = authService.currentUser?.id {
                    matchService.fetchMatches(for: userID)
                }
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
            if let userID = authService.currentUser?.id {
                matchService.fetchMatches(for: userID)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search matches", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(MatchFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var matchList: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredMatches) { match in
                        MatchRow(match: match) {
                            selectedMatch = match
                            showingMatchDetail = true
                        }
                    }
                }
                .padding()
            }
            
            if matchService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
            
            if filteredMatches.isEmpty && !matchService.isLoading {
                EmptyStateView(filter: selectedFilter)
            }
        }
    }
    
    private var filteredMatches: [Match] {
        var matches: [Match] = []
        
        switch selectedFilter {
        case .upcoming:
            matches = matchService.upcomingMatches
        case .current:
            matches = matchService.currentMatches
        case .past:
            matches = matchService.pastMatches
        }
        
        if !searchText.isEmpty {
            return matches.filter { match in
                match.location.lowercased().contains(searchText.lowercased())
            }
        }
        
        return matches
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)) : Color.white)
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct MatchRow: View {
    let match: Match
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(match.location)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    StatusBadge(match: match)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    
                    Text(match.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.gray)
                    
                    Text("\(match.registeredPlayersCount)/\(match.maxPlayers) players")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let filter: MatchesView.MatchFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text(submessage)
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var imageName: String {
        switch filter {
        case .upcoming:
            return "calendar.badge.plus"
        case .current:
            return "sportscourt"
        case .past:
            return "clock.arrow.circlepath"
        }
    }
    
    private var message: String {
        switch filter {
        case .upcoming:
            return "No upcoming matches found"
        case .current:
            return "No active matches right now"
        case .past:
            return "No past matches yet"
        }
    }
    
    private var submessage: String {
        switch filter {
        case .upcoming:
            return "Create a new match or register for an existing one"
        case .current:
            return "Your matches in progress will appear here"
        case .past:
            return "Your completed matches will appear here"
        }
    }
}

struct MatchesView_Previews: PreviewProvider {
    static var previews: some View {
        MatchesView()
            .environmentObject(AuthService())
            .environmentObject(MatchService())
    }
} 