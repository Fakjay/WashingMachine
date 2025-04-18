import Foundation
@testable import WashingMachine

struct MockData {
    static let users: [User] = [
        User(
            id: "user1",
            name: "John Doe",
            email: "john@example.com",
            skillLevel: .intermediate,
            phoneNumber: "123-456-7890",
            location: "New York",
            matchHistory: ["match1", "match2"],
            wins: 10,
            losses: 5,
            eloRating: 1200
        ),
        User(
            id: "user2",
            name: "Jane Smith",
            email: "jane@example.com",
            skillLevel: .advanced,
            phoneNumber: "987-654-3210",
            location: "Los Angeles",
            matchHistory: ["match1", "match3"],
            wins: 15,
            losses: 2,
            eloRating: 1500
        ),
        User(
            id: "user3",
            name: "Bob Johnson",
            email: "bob@example.com",
            skillLevel: .beginner,
            phoneNumber: "555-123-4567",
            location: "Chicago",
            matchHistory: ["match2", "match3"],
            wins: 3,
            losses: 8,
            eloRating: 900
        )
    ]
    
    static let matches: [Match] = [
        Match(
            id: "match1",
            player1Id: "user1",
            player2Id: "user2",
            createdBy: "user1",
            location: "Tennis Court A",
            scheduledDate: Date().addingTimeInterval(-86400), // Yesterday
            status: .completed,
            winner: "user2",
            sets: [
                MatchSet(player1Score: 4, player2Score: 6),
                MatchSet(player1Score: 6, player2Score: 3),
                MatchSet(player1Score: 4, player2Score: 6)
            ]
        ),
        Match(
            id: "match2",
            player1Id: "user1",
            player2Id: "user3",
            createdBy: "user1",
            location: "Tennis Court B",
            scheduledDate: Date().addingTimeInterval(-172800), // 2 days ago
            status: .completed,
            winner: "user1",
            sets: [
                MatchSet(player1Score: 6, player2Score: 2),
                MatchSet(player1Score: 6, player2Score: 1)
            ]
        ),
        Match(
            id: "match3",
            player1Id: "user2",
            player2Id: "user3",
            createdBy: "user2",
            location: "Tennis Court C",
            scheduledDate: Date().addingTimeInterval(86400), // Tomorrow
            status: .pending
        )
    ]
} 