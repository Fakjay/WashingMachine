import Foundation
import Firebase
import FirebaseFirestore
import Combine

class MatchService: ObservableObject {
    @Published var upcomingMatches: [Match] = []
    @Published var currentMatches: [Match] = []
    @Published var pastMatches: [Match] = []
    @Published var selectedMatch: Match?
    @Published var isLoading = false
    @Published var error: String?
    
    private var listeners: [ListenerRegistration] = []
    private var db = Firestore.firestore()
    
    func fetchMatches(for userID: String) {
        isLoading = true
        error = nil
        
        let now = Date()
        
        // Fetch upcoming matches
        db.collection("matches")
            .whereField("date", isGreaterThan: now)
            .whereField("isCompleted", isEqualTo: false)
            .order(by: "date", descending: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                self.upcomingMatches = snapshot?.documents
                    .compactMap { try? $0.data(as: Match.self) } ?? []
                
                self.isLoading = false
            }
        
        // Fetch ongoing matches for this user
        db.collection("matches")
            .whereField("registeredPlayerIDs", arrayContains: userID)
            .whereField("isCompleted", isEqualTo: false)
            .whereField("date", isLessThanOrEqualTo: now)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                self.currentMatches = snapshot?.documents
                    .compactMap { try? $0.data(as: Match.self) } ?? []
            }
        
        // Fetch past matches
        db.collection("matches")
            .whereField("registeredPlayerIDs", arrayContains: userID)
            .whereField("isCompleted", isEqualTo: true)
            .order(by: "date", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                self.pastMatches = snapshot?.documents
                    .compactMap { try? $0.data(as: Match.self) } ?? []
            }
    }
    
    func listenToMatch(matchID: String) {
        // Remove any existing listeners
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        isLoading = true
        
        let matchListener = db.collection("matches").document(matchID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let data = snapshot?.data(),
                      let match = try? Firestore.Decoder().decode(Match.self, from: data) else {
                    self.error = "Failed to decode match data"
                    return
                }
                
                self.selectedMatch = match
            }
        
        listeners.append(matchListener)
    }
    
    func createMatch(creatorID: String, date: Date, location: String, courtNumbers: [String], maxPlayers: Int, visibility: MatchVisibility, inviteCode: String? = nil, gamesPerSet: Int = 6, enableGoldenPoint: Bool = true, numberOfRounds: Int = 3) {
        isLoading = true
        error = nil
        
        let newMatch = Match(
            id: UUID().uuidString,
            creatorID: creatorID,
            date: date,
            location: location,
            courtNumbers: courtNumbers,
            maxPlayers: maxPlayers,
            visibility: visibility,
            inviteCode: visibility == .private ? inviteCode : nil,
            registeredPlayerIDs: [creatorID],  // Auto-register the creator
            gamesPerSet: gamesPerSet,
            enableGoldenPoint: enableGoldenPoint,
            numberOfRounds: numberOfRounds
        )
        
        do {
            try db.collection("matches").document(newMatch.id).setData(from: newMatch)
            self.selectedMatch = newMatch
            self.isLoading = false
            
            // Update user's match history
            db.collection("users").document(creatorID).updateData([
                "matchHistory": FieldValue.arrayUnion([newMatch.id])
            ])
            
            // TODO: Send notifications to friends or relevant users
            
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func registerForMatch(matchID: String, userID: String, inviteCode: String? = nil) {
        isLoading = true
        error = nil
        
        db.collection("matches").document(matchID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error.localizedDescription
                self.isLoading = false
                return
            }
            
            guard let data = snapshot?.data(),
                  let match = try? Firestore.Decoder().decode(Match.self, from: data) else {
                self.error = "Failed to decode match data"
                self.isLoading = false
                return
            }
            
            if match.isRegistrationFull {
                self.error = "Match is already full"
                self.isLoading = false
                return
            }
            
            if match.registeredPlayerIDs.contains(userID) {
                self.error = "You are already registered for this match"
                self.isLoading = false
                return
            }
            
            if match.visibility == .private, inviteCode != match.inviteCode {
                self.error = "Invalid invite code"
                self.isLoading = false
                return
            }
            
            // Register the user
            db.collection("matches").document(matchID).updateData([
                "registeredPlayerIDs": FieldValue.arrayUnion([userID])
            ]) { error in
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                // Update user's match history
                db.collection("users").document(userID).updateData([
                    "matchHistory": FieldValue.arrayUnion([matchID])
                ])
                
                // If we now have enough players, create the first round
                if match.registeredPlayersCount + 1 == match.maxPlayers {
                    self.createFirstRound(match: match, withNewPlayerID: userID)
                }
            }
        }
    }
    
    func submitSetScore(matchID: String, setID: String, team1Score: Int, team2Score: Int) {
        isLoading = true
        error = nil
        
        // First, fetch the current match and set
        db.collection("matches").document(matchID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error.localizedDescription
                self.isLoading = false
                return
            }
            
            guard var match = try? snapshot?.data(as: Match.self),
                  let setIndex = match.sets.firstIndex(where: { $0.id == setID }) else {
                self.error = "Match or set not found"
                self.isLoading = false
                return
            }
            
            // Update the set scores
            match.sets[setIndex].teams[0].gamesWon = team1Score
            match.sets[setIndex].teams[1].gamesWon = team2Score
            match.sets[setIndex].isCompleted = true
            match.sets[setIndex].completedAt = Date()
            
            // Update the match in Firestore
            do {
                try db.collection("matches").document(matchID).setData(from: match)
                
                // Update players' Elo ratings
                self.updatePlayerRatings(for: match.sets[setIndex])
                
                // Check if all sets for this round are completed
                if match.isAllSetsCompletedForRound(match.sets[setIndex].roundNumber) && 
                   match.currentRound <= match.numberOfRounds {
                    self.createNextRound(match: match)
                } else if match.currentRound > match.numberOfRounds {
                    // If we've completed all rounds, mark the match as completed
                    db.collection("matches").document(matchID).updateData([
                        "isCompleted": true
                    ])
                    
                    // Calculate final results and update player stats
                    self.finishMatch(match: match)
                }
                
                self.isLoading = false
            } catch {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func createFirstRound(match: Match, withNewPlayerID: String? = nil) {
        // Create a local copy with the new player if needed
        var updatedMatch = match
        if let newPlayerID = withNewPlayerID {
            updatedMatch.registeredPlayerIDs.append(newPlayerID)
        }
        
        // 1. Fetch all player data to get their ratings
        fetchPlayersData(playerIDs: updatedMatch.registeredPlayerIDs) { [weak self] players in
            guard let self = self, !players.isEmpty else { return }
            
            // 2. Generate pairs based on Elo ratings
            let pairs = self.generateBalancedPairs(players: players)
            
            // 3. Create sets for each court
            var sets: [MatchSet] = []
            
            for (index, courtPairs) in pairs.enumerated() {
                guard index < updatedMatch.courtNumbers.count, courtPairs.count == 2 else { continue }
                
                let team1 = Team(
                    id: UUID().uuidString,
                    playerIDs: courtPairs[0].map { $0.id }
                )
                
                let team2 = Team(
                    id: UUID().uuidString,
                    playerIDs: courtPairs[1].map { $0.id }
                )
                
                let newSet = MatchSet(
                    id: UUID().uuidString,
                    matchID: updatedMatch.id,
                    teams: [team1, team2],
                    roundNumber: 1,
                    courtNumber: updatedMatch.courtNumbers[index]
                )
                
                sets.append(newSet)
            }
            
            // 4. Update the match with the new sets
            updatedMatch.sets.append(contentsOf: sets)
            
            // 5. Update in Firestore
            do {
                try self.db.collection("matches").document(updatedMatch.id).setData(from: updatedMatch)
                
                // 6. Send notifications to all players
                self.sendPairingNotifications(match: updatedMatch, sets: sets)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    private func createNextRound(match: Match) {
        // 1. Get all players and their updated Elo ratings
        fetchPlayersData(playerIDs: match.registeredPlayerIDs) { [weak self] players in
            guard let self = self, !players.isEmpty else { return }
            
            // 2. Generate new pairs based on updated Elo ratings
            let pairs = self.generateBalancedPairs(players: players, match: match)
            
            // 3. Create sets for each court
            var sets: [MatchSet] = []
            let newRoundNumber = match.currentRound
            
            for (index, courtPairs) in pairs.enumerated() {
                guard index < match.courtNumbers.count, courtPairs.count == 2 else { continue }
                
                let team1 = Team(
                    id: UUID().uuidString,
                    playerIDs: courtPairs[0].map { $0.id }
                )
                
                let team2 = Team(
                    id: UUID().uuidString,
                    playerIDs: courtPairs[1].map { $0.id }
                )
                
                let newSet = MatchSet(
                    id: UUID().uuidString,
                    matchID: match.id,
                    teams: [team1, team2],
                    roundNumber: newRoundNumber,
                    courtNumber: match.courtNumbers[index]
                )
                
                sets.append(newSet)
            }
            
            // 4. Update the match with the new sets
            var updatedMatch = match
            updatedMatch.sets.append(contentsOf: sets)
            
            // 5. Update in Firestore
            do {
                try self.db.collection("matches").document(updatedMatch.id).setData(from: updatedMatch)
                
                // 6. Send notifications to all players
                self.sendPairingNotifications(match: updatedMatch, sets: sets)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    private func fetchPlayersData(playerIDs: [String], completion: @escaping ([User]) -> Void) {
        let group = DispatchGroup()
        var players: [User] = []
        
        for playerID in playerIDs {
            group.enter()
            
            db.collection("users").document(playerID).getDocument { snapshot, error in
                defer { group.leave() }
                
                if error == nil, let data = snapshot?.data() {
                    if let player = try? Firestore.Decoder().decode(User.self, from: data) {
                        players.append(player)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(players)
        }
    }
    
    private func generateBalancedPairs(players: [User], match: Match? = nil) -> [[[User]]] {
        // Sort players by Elo rating
        let sortedPlayers = players.sorted { $0.eloRating > $1.eloRating }
        
        // Create pairs with balanced ratings (strongest with weakest, 2nd strongest with 2nd weakest, etc.)
        var pairs: [[User]] = []
        
        for i in 0..<sortedPlayers.count/2 {
            let player1 = sortedPlayers[i]
            let player2 = sortedPlayers[sortedPlayers.count - 1 - i]
            pairs.append([player1, player2])
        }
        
        // If there's a match, avoid repeating the same pairs from previous rounds
        if let match = match {
            // Try to avoid pairs that have already played together
            var existingPairings = Set<String>()
            
            for set in match.sets {
                for team in set.teams {
                    if team.playerIDs.count == 2 {
                        let pairKey = [team.playerIDs[0], team.playerIDs[1]].sorted().joined(separator: "-")
                        existingPairings.insert(pairKey)
                    }
                }
            }
            
            // Try to rearrange pairs to avoid repetitions without unbalancing too much
            // This is a simple approach - could be more sophisticated
            var attemptCount = 0
            var newPairs = pairs
            
            while attemptCount < 3 {
                var foundRepetition = false
                
                for i in 0..<newPairs.count {
                    let pair = newPairs[i]
                    let pairKey = [pair[0].id, pair[1].id].sorted().joined(separator: "-")
                    
                    if existingPairings.contains(pairKey) {
                        // Found a repeated pair, try to swap with the next pair
                        if i < newPairs.count - 1 {
                            let nextPair = newPairs[i + 1]
                            // Create two new pairs
                            newPairs[i] = [pair[0], nextPair[1]]
                            newPairs[i + 1] = [pair[1], nextPair[0]]
                            foundRepetition = true
                            break
                        }
                    }
                }
                
                if !foundRepetition {
                    break
                }
                
                attemptCount += 1
            }
            
            pairs = newPairs
        }
        
        // Group pairs for each court (2 pairs per court = 4 players)
        var courtPairs: [[[User]]] = []
        
        for i in stride(from: 0, to: pairs.count, by: 2) {
            if i + 1 < pairs.count {
                courtPairs.append([pairs[i], pairs[i + 1]])
            } else if i < pairs.count {
                // Handle odd number of pairs
                courtPairs.append([pairs[i]])
            }
        }
        
        return courtPairs
    }
    
    private func updatePlayerRatings(for set: MatchSet) {
        guard set.isCompleted, set.teams.count == 2 else { return }
        
        let team1 = set.teams[0]
        let team2 = set.teams[1]
        
        let team1Score = Double(team1.gamesWon)
        let team2Score = Double(team2.gamesWon)
        let totalGames = team1Score + team2Score
        
        guard totalGames > 0 else { return }
        
        // Calculate actual outcomes (0 to 1)
        let team1Result = team1Score / totalGames
        let team2Result = team2Score / totalGames
        
        // Fetch players to update their ratings
        fetchPlayersData(playerIDs: set.playerIDs) { [weak self] players in
            guard let self = self else { return }
            
            var team1Players = players.filter { team1.playerIDs.contains($0.id) }
            var team2Players = players.filter { team2.playerIDs.contains($0.id) }
            
            // Calculate team ratings (average of player ratings)
            let team1Rating = team1Players.reduce(0) { $0 + $1.eloRating } / team1Players.count
            let team2Rating = team2Players.reduce(0) { $0 + $1.eloRating } / team2Players.count
            
            // Calculate expected outcomes using Elo formula
            let expectedTeam1 = 1.0 / (1.0 + pow(10, Double(team2Rating - team1Rating) / 400.0))
            let expectedTeam2 = 1.0 / (1.0 + pow(10, Double(team1Rating - team2Rating) / 400.0))
            
            // Update each player's rating
            for i in 0..<team1Players.count {
                // K-factor is higher for newer players with fewer games
                let kFactor = (team1Players[i].wins + team1Players[i].losses < 10) ? 32 : 16
                let ratingChange = Int(Double(kFactor) * (team1Result - expectedTeam1))
                team1Players[i].eloRating += ratingChange
                
                // Update in Firestore
                self.db.collection("users").document(team1Players[i].id).updateData([
                    "eloRating": team1Players[i].eloRating
                ])
            }
            
            for i in 0..<team2Players.count {
                let kFactor = (team2Players[i].wins + team2Players[i].losses < 10) ? 32 : 16
                let ratingChange = Int(Double(kFactor) * (team2Result - expectedTeam2))
                team2Players[i].eloRating += ratingChange
                
                // Update in Firestore
                self.db.collection("users").document(team2Players[i].id).updateData([
                    "eloRating": team2Players[i].eloRating
                ])
            }
        }
    }
    
    private func finishMatch(match: Match) {
        // Calculate player stats
        var playerStats: [String: (wins: Int, points: Int)] = [:]
        
        // Initialize stats for all players
        for playerID in match.registeredPlayerIDs {
            playerStats[playerID] = (0, 0)
        }
        
        // Count wins and points for each player
        for set in match.sets where set.isCompleted {
            if let winningTeam = set.winningTeam {
                // Add a win for the winning team players
                for playerID in winningTeam.playerIDs {
                    var stats = playerStats[playerID] ?? (0, 0)
                    stats.wins += 1
                    stats.points += winningTeam.gamesWon
                    playerStats[playerID] = stats
                }
                
                // Add points for the losing team players
                let losingTeam = set.teams.first { $0.id != winningTeam.id }
                if let losingTeam = losingTeam {
                    for playerID in losingTeam.playerIDs {
                        var stats = playerStats[playerID] ?? (0, 0)
                        stats.points += losingTeam.gamesWon
                        playerStats[playerID] = stats
                    }
                }
            }
        }
        
        // Determine the winner(s) based on most wins, then most points
        let sortedPlayers = playerStats.sorted { (player1, player2) -> Bool in
            if player1.value.wins != player2.value.wins {
                return player1.value.wins > player2.value.wins
            }
            return player1.value.points > player2.value.points
        }
        
        // Update player win/loss records
        if let topPlayer = sortedPlayers.first {
            let topScore = topPlayer.value
            
            for (playerID, stats) in playerStats {
                // Update wins for top players (those tied for first)
                if stats.wins == topScore.wins && stats.points == topScore.points {
                    db.collection("users").document(playerID).updateData([
                        "wins": FieldValue.increment(Int64(1))
                    ])
                } else {
                    db.collection("users").document(playerID).updateData([
                        "losses": FieldValue.increment(Int64(1))
                    ])
                }
            }
        }
        
        // Final match update to include top performers
        if !sortedPlayers.isEmpty {
            let topPlayerIDs = sortedPlayers.prefix(3).map { $0.key }
            
            db.collection("matches").document(match.id).updateData([
                "topPerformers": topPlayerIDs
            ])
        }
    }
    
    private func sendPairingNotifications(match: Match, sets: [MatchSet]) {
        // In a real app, this would connect to Firebase Cloud Messaging or APNS
        // For this implementation, we'll just log the notifications
        
        print("Sending pairing notifications for match: \(match.id)")
        
        for set in sets {
            let courtMsg = "Court: \(set.courtNumber)"
            let roundMsg = "Round: \(set.roundNumber)"
            let team1Msg = "Team 1: \(set.teams[0].playerIDs.joined(separator: ", "))"
            let team2Msg = "Team 2: \(set.teams[1].playerIDs.joined(separator: ", "))"
            
            print("\(courtMsg) - \(roundMsg)")
            print("\(team1Msg) vs \(team2Msg)")
            print("---")
            
            // In a real app: 
            // Send push notifications to each player in the set
            // Store notification records in Firestore
        }
    }
} 