import Foundation

enum SkillLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var id: String { self.rawValue }
}

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var skillLevel: SkillLevel
    var avatarURL: URL?
    var phoneNumber: String?
    var location: String?
    var matchHistory: [String] = [] // References to match IDs
    var wins: Int = 0
    var losses: Int = 0
    var eloRating: Int = 1000 // Starting ELO rating
    var createdAt: Date = Date()
    
    var winPercentage: Double {
        let total = wins + losses
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total)
    }
    
    var formattedWinLoss: String {
        return "\(wins)W - \(losses)L"
    }
} 