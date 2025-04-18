import Foundation

struct Team: Codable, Identifiable, Equatable {
    var id: String
    var playerIDs: [String]
    var gamesWon: Int = 0
    
    static func == (lhs: Team, rhs: Team) -> Bool {
        return lhs.id == rhs.id
    }
}

struct MatchSet: Identifiable, Codable {
    var id: String
    var matchID: String
    var teams: [Team]
    var roundNumber: Int
    var courtNumber: String
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?
    
    var winningTeam: Team? {
        guard isCompleted else { return nil }
        return teams.max(by: { $0.gamesWon < $1.gamesWon })
    }
    
    var scoreString: String {
        guard teams.count == 2 else { return "Invalid Score" }
        return "\(teams[0].gamesWon) - \(teams[1].gamesWon)"
    }
    
    var playerIDs: [String] {
        return teams.flatMap { $0.playerIDs }
    }
} 