import Foundation

enum MatchVisibility: String, Codable, CaseIterable, Identifiable {
    case `public` = "Public"
    case `private` = "Private"
    
    var id: String { self.rawValue }
}

struct Match: Identifiable, Codable {
    var id: String
    var creatorID: String
    var date: Date
    var location: String
    var courtNumbers: [String]
    var maxPlayers: Int
    var visibility: MatchVisibility
    var inviteCode: String?
    var registeredPlayerIDs: [String] = []
    var sets: [MatchSet] = []
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    
    // Match configuration
    var gamesPerSet: Int = 6
    var enableGoldenPoint: Bool = true
    var numberOfRounds: Int = 3
    
    var registeredPlayersCount: Int {
        return registeredPlayerIDs.count
    }
    
    var isRegistrationFull: Bool {
        return registeredPlayersCount >= maxPlayers
    }
    
    var currentRound: Int {
        let completedRounds = sets.filter { $0.isCompleted }.reduce(into: Set<Int>()) { $0.insert($1.roundNumber) }
        return completedRounds.count + 1
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func canUserRegister(userID: String) -> Bool {
        return !isRegistrationFull && !registeredPlayerIDs.contains(userID) && !isCompleted
    }
    
    func isAllSetsCompletedForRound(_ round: Int) -> Bool {
        let setsInRound = sets.filter { $0.roundNumber == round }
        let expectedSetsCount = maxPlayers / 4 // 4 players per court
        return setsInRound.count == expectedSetsCount && setsInRound.allSatisfy { $0.isCompleted }
    }
} 