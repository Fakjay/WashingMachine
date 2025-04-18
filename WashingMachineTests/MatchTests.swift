import XCTest
@testable import WashingMachine

class MatchTests: XCTestCase {
    
    func testMatchInitialization() {
        // Given
        let matchId = "testMatchId"
        let player1Id = "player1"
        let player2Id = "player2"
        let createdBy = "player1"
        let location = "Tennis Court 1"
        let date = Date()
        
        // When
        let match = Match(
            id: matchId,
            player1Id: player1Id,
            player2Id: player2Id,
            createdBy: createdBy,
            location: location,
            scheduledDate: date
        )
        
        // Then
        XCTAssertEqual(match.id, matchId)
        XCTAssertEqual(match.player1Id, player1Id)
        XCTAssertEqual(match.player2Id, player2Id)
        XCTAssertEqual(match.createdBy, createdBy)
        XCTAssertEqual(match.location, location)
        XCTAssertEqual(match.scheduledDate, date)
        XCTAssertNil(match.winner)
        XCTAssertEqual(match.status, .pending)
        XCTAssertTrue(match.sets.isEmpty)
    }
    
    func testAddSet() {
        // Given
        var match = Match(
            id: "testMatch",
            player1Id: "player1",
            player2Id: "player2", 
            createdBy: "player1",
            location: "Tennis Court",
            scheduledDate: Date()
        )
        
        let matchSet = MatchSet(player1Score: 6, player2Score: 4)
        
        // When
        match.sets.append(matchSet)
        
        // Then
        XCTAssertEqual(match.sets.count, 1)
        XCTAssertEqual(match.sets.first?.player1Score, 6)
        XCTAssertEqual(match.sets.first?.player2Score, 4)
    }
    
    func testDetermineWinner() {
        // Given
        var match = Match(
            id: "testMatch",
            player1Id: "player1",
            player2Id: "player2", 
            createdBy: "player1",
            location: "Tennis Court",
            scheduledDate: Date()
        )
        
        // When - Player 1 wins 2 sets
        match.sets.append(MatchSet(player1Score: 6, player2Score: 4))
        match.sets.append(MatchSet(player1Score: 6, player2Score: 3))
        match.complete(withWinnerId: "player1")
        
        // Then
        XCTAssertEqual(match.winner, "player1")
        XCTAssertEqual(match.status, .completed)
    }
} 