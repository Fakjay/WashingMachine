import XCTest
@testable import WashingMachine

class UserTests: XCTestCase {
    
    func testUserInitialization() {
        // Given
        let userId = "testUserId"
        let name = "John Doe"
        let email = "john.doe@example.com"
        let skillLevel = SkillLevel.intermediate
        
        // When
        let user = User(id: userId, name: name, email: email, skillLevel: skillLevel)
        
        // Then
        XCTAssertEqual(user.id, userId)
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.skillLevel, skillLevel)
        XCTAssertEqual(user.wins, 0)
        XCTAssertEqual(user.losses, 0)
        XCTAssertEqual(user.eloRating, 1000)
        XCTAssertTrue(user.matchHistory.isEmpty)
    }
    
    func testWinPercentage() {
        // Given
        var user = User(id: "testId", name: "Test User", email: "test@example.com", skillLevel: .beginner)
        
        // When & Then
        XCTAssertEqual(user.winPercentage, 0)
        
        // When
        user.wins = 3
        user.losses = 1
        
        // Then
        XCTAssertEqual(user.winPercentage, 0.75)
        
        // When
        user.wins = 0
        user.losses = 5
        
        // Then
        XCTAssertEqual(user.winPercentage, 0)
    }
    
    func testFormattedWinLoss() {
        // Given
        var user = User(id: "testId", name: "Test User", email: "test@example.com", skillLevel: .beginner)
        
        // When
        user.wins = 10
        user.losses = 5
        
        // Then
        XCTAssertEqual(user.formattedWinLoss, "10W - 5L")
    }
} 