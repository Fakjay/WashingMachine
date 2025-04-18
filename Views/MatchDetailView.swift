import SwiftUI

struct MatchDetailView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var matchService: MatchService
    @Environment(\.presentationMode) private var presentationMode
    
    let match: Match
    
    @State private var showingScoreInput = false
    @State private var selectedSet: MatchSet?
    @State private var showingInviteOptions = false
    @State private var inviteLink = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Match Header
                MatchHeaderView(match: match)
                
                // Player list
                PlayerListView(match: match)
                
                // Court assignments & results
                if !match.sets.isEmpty {
                    CourtsView(
                        match: match,
                        onScoreInput: { set in
                            selectedSet = set
                            showingScoreInput = true
                        }
                    )
                }
                
                // Registration section
                if !match.isCompleted && !match.isRegistrationFull {
                    RegistrationView(match: match)
                }
                
                // Share / Invite section
                if let user = authService.currentUser, match.creatorID == user.id {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Invite Players")
                            .font(.headline)
                            
                        Button(action: {
                            showingInviteOptions = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Invite Link")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 3)
                }
                
                // Match completed status
                if match.isCompleted {
                    MatchCompletedView(match: match)
                }
            }
            .padding()
            .background(Color(#colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)))
        }
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            matchService.listenToMatch(matchID: match.id)
        }
        .sheet(isPresented: $showingScoreInput) {
            if let set = selectedSet {
                ScoreInputView(set: set, matchID: match.id)
                    .environmentObject(matchService)
            }
        }
        .sheet(isPresented: $showingInviteOptions) {
            InviteOptionsView(match: match)
        }
    }
}

struct MatchHeaderView: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(match.location)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                StatusBadge(match: match)
            }
            
            HStack {
                Label(match.formattedDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Courts: \(match.courtNumbers.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(match.registeredPlayersCount)/\(match.maxPlayers) players", systemImage: "person.2")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(match.visibility.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Match rules
            VStack(alignment: .leading, spacing: 5) {
                Text("Match Rules")
                    .font(.headline)
                    .padding(.top, 5)
                
                HStack {
                    Text("Games per set: \(match.gamesPerSet)")
                    Spacer()
                    Text("Rounds: \(match.numberOfRounds)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text("Golden point: \(match.enableGoldenPoint ? "Enabled" : "Disabled")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
}

struct StatusBadge: View {
    let match: Match
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.2))
        .cornerRadius(20)
    }
    
    private var statusText: String {
        if match.isCompleted {
            return "Completed"
        } else if match.date > Date() {
            return "Upcoming"
        } else {
            return "In Progress"
        }
    }
    
    private var statusColor: Color {
        if match.isCompleted {
            return .blue
        } else if match.date > Date() {
            return .orange
        } else {
            return .green
        }
    }
}

struct PlayerListView: View {
    let match: Match
    @EnvironmentObject private var authService: AuthService
    
    @State private var players: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Players")
                .font(.headline)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if players.isEmpty {
                Text("No players registered yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(players) { player in
                        PlayerCell(player: player)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
        .onAppear {
            loadPlayers()
        }
    }
    
    private func loadPlayers() {
        isLoading = true
        
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var loadedPlayers: [User] = []
        
        for playerID in match.registeredPlayerIDs {
            group.enter()
            
            db.collection("users").document(playerID).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let data = snapshot?.data(),
                   let player = try? Firestore.Decoder().decode(User.self, from: data) {
                    loadedPlayers.append(player)
                }
            }
        }
        
        group.notify(queue: .main) {
            self.players = loadedPlayers.sorted { $0.eloRating > $1.eloRating }
            self.isLoading = false
        }
    }
}

struct PlayerCell: View {
    let player: User
    
    var body: some View {
        HStack {
            if let url = player.avatarURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.gray)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(player.skillLevel.rawValue) • \(player.eloRating)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
        .cornerRadius(10)
    }
}

struct CourtsView: View {
    let match: Match
    let onScoreInput: (MatchSet) -> Void
    
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Courts & Results")
                .font(.headline)
            
            if match.sets.isEmpty {
                Text("Pairings will be generated when all players have registered.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                // Group sets by round
                ForEach(Array(Set(match.sets.map { $0.roundNumber })).sorted(), id: \.self) { round in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Round \(round)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top, 5)
                        
                        ForEach(match.sets.filter { $0.roundNumber == round }) { set in
                            SetCard(set: set, onScoreInput: onScoreInput, canInputScore: canInputScore(for: set))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
    
    private func canInputScore(for set: MatchSet) -> Bool {
        guard !match.isCompleted, !set.isCompleted,
              let currentUser = authService.currentUser else {
            return false
        }
        
        // Check if user is part of this set
        return set.playerIDs.contains(currentUser.id)
    }
}

struct SetCard: View {
    let set: MatchSet
    let onScoreInput: (MatchSet) -> Void
    let canInputScore: Bool
    
    @State private var players: [String: User] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Court \(set.courtNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if set.isCompleted {
                    Text("Final: \(set.scoreString)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                } else {
                    Text("In Progress")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Team 1
            HStack {
                VStack(alignment: .leading) {
                    Text("Team 1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(set.teams[0].playerIDs, id: \.self) { playerID in
                        Text(players[playerID]?.name ?? "Player")
                            .font(.footnote)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if set.isCompleted {
                    Text("\(set.teams[0].gamesWon)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(set.winningTeam?.id == set.teams[0].id ? .green : .primary)
                }
            }
            
            // Team 2
            HStack {
                VStack(alignment: .leading) {
                    Text("Team 2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(set.teams[1].playerIDs, id: \.self) { playerID in
                        Text(players[playerID]?.name ?? "Player")
                            .font(.footnote)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if set.isCompleted {
                    Text("\(set.teams[1].gamesWon)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(set.winningTeam?.id == set.teams[1].id ? .green : .primary)
                }
            }
            
            if canInputScore {
                Button(action: {
                    onScoreInput(set)
                }) {
                    Text("Enter Score")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
        .cornerRadius(10)
        .onAppear {
            loadPlayers()
        }
    }
    
    private func loadPlayers() {
        let db = Firestore.firestore()
        let playerIDs = set.playerIDs
        
        for playerID in playerIDs {
            db.collection("users").document(playerID).getDocument { snapshot, error in
                if let data = snapshot?.data(),
                   let player = try? Firestore.Decoder().decode(User.self, from: data) {
                    DispatchQueue.main.async {
                        self.players[playerID] = player
                    }
                }
            }
        }
    }
}

struct RegistrationView: View {
    let match: Match
    
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var matchService: MatchService
    
    @State private var showingInviteCodePrompt = false
    @State private var inviteCode = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Registration")
                .font(.headline)
            
            HStack {
                Text("\(match.registeredPlayersCount)/\(match.maxPlayers) players registered")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let user = authService.currentUser {
                    if match.registeredPlayerIDs.contains(user.id) {
                        Label("Registered", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else if match.canUserRegister(userID: user.id) {
                        Button(action: registerForMatch) {
                            Text("Register")
                                .font(.subheadline)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            if matchService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            
            if let error = matchService.error {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
        .alert("Enter Invite Code", isPresented: $showingInviteCodePrompt) {
            TextField("Invite Code", text: $inviteCode)
            
            Button("Cancel", role: .cancel) {}
            Button("Submit") {
                if let userID = authService.currentUser?.id {
                    matchService.registerForMatch(matchID: match.id, userID: userID, inviteCode: inviteCode)
                }
            }
        } message: {
            Text("This is a private match. Please enter the invite code to join.")
        }
    }
    
    private func registerForMatch() {
        guard let userID = authService.currentUser?.id else { return }
        
        if match.visibility == .private {
            showingInviteCodePrompt = true
        } else {
            matchService.registerForMatch(matchID: match.id, userID: userID)
        }
    }
}

struct MatchCompletedView: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title)
                
                Text("Match Completed")
                    .font(.headline)
            }
            
            Text("Congratulations to all players!")
                .font(.subheadline)
            
            Text("Time for a refreshing sip of beer! 🍻")
                .font(.subheadline)
                .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
}

struct ScoreInputView: View {
    let set: MatchSet
    let matchID: String
    
    @EnvironmentObject private var matchService: MatchService
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var team1Score = 0
    @State private var team2Score = 0
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Text("Enter Score")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Court \(set.courtNumber)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Divider()
                
                // Team 1 score
                VStack(spacing: 12) {
                    Text("Team 1")
                        .font(.headline)
                    
                    HStack {
                        Button(action: { if team1Score > 0 { team1Score -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        
                        Text("\(team1Score)")
                            .font(.system(size: 48, weight: .semibold))
                            .frame(width: 80)
                        
                        Button(action: { team1Score += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
                .cornerRadius(12)
                
                // Team 2 score
                VStack(spacing: 12) {
                    Text("Team 2")
                        .font(.headline)
                    
                    HStack {
                        Button(action: { if team2Score > 0 { team2Score -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        
                        Text("\(team2Score)")
                            .font(.system(size: 48, weight: .semibold))
                            .frame(width: 80)
                        
                        Button(action: { team2Score += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: submitScore) {
                    HStack {
                        Text("Submit Score")
                            .fontWeight(.medium)
                        
                        if isSubmitting {
                            ProgressView()
                                .padding(.leading, 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isSubmitting)
                .padding(.bottom, 30)
            }
            .padding()
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func submitScore() {
        isSubmitting = true
        
        matchService.submitSetScore(
            matchID: matchID,
            setID: set.id,
            team1Score: team1Score,
            team2Score: team2Score
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct InviteOptionsView: View {
    let match: Match
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.2.badge.gearshape")
                    .font(.system(size: 70))
                    .foregroundColor(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                    .padding(.top, 30)
                
                Text("Invite Players")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Match details")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: copyMatchDetails) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text("Location: \(match.location)")
                        .font(.subheadline)
                    
                    Text("Date: \(match.formattedDate)")
                        .font(.subheadline)
                    
                    if match.visibility == .private, let inviteCode = match.inviteCode {
                        Text("Invite Code: \(inviteCode)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.top, 5)
                    }
                }
                .padding()
                .background(Color(#colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9607843137, alpha: 1)))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button(action: shareInvite) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Invite")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(#colorLiteral(red: 0.1294117647, green: 0.6, blue: 0.5254901961, alpha: 1)))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func copyMatchDetails() {
        var text = "Join my Padel Tennis match!\n"
        text += "Location: \(match.location)\n"
        text += "Date: \(match.formattedDate)\n"
        
        if match.visibility == .private, let inviteCode = match.inviteCode {
            text += "Invite Code: \(inviteCode)\n"
        }
        
        UIPasteboard.general.string = text
    }
    
    private func shareInvite() {
        var items: [Any] = []
        
        var text = "Join my Padel Tennis match!\n"
        text += "Location: \(match.location)\n"
        text += "Date: \(match.formattedDate)\n"
        
        if match.visibility == .private, let inviteCode = match.inviteCode {
            text += "Invite Code: \(inviteCode)\n"
        }
        
        items.append(text)
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Find the currently presented UIViewController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController,
           let presentedVC = rootVC.presentedViewController {
            presentedVC.present(activityVC, animated: true)
        }
    }
}

struct MatchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MatchDetailView(match: Match(
            id: "preview",
            creatorID: "user1",
            date: Date(),
            location: "Tennis Club",
            courtNumbers: ["1", "2"],
            maxPlayers: 8,
            visibility: .public
        ))
        .environmentObject(AuthService())
        .environmentObject(MatchService())
    }
} 