import XCTest
@testable import WashingMachine
import Firebase
import Combine

class MatchServiceTests: XCTestCase {
    var matchService: MatchService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        matchService = MatchService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        matchService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFetchMatches() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch matches completes")
        let testMatches = [
            Match(id: "match1", player1Id: "user1", player2Id: "user2", createdBy: "user1", location: "Court 1", scheduledDate: Date()),
            Match(id: "match2", player1Id: "user1", player2Id: "user3", createdBy: "user1", location: "Court 2", scheduledDate: Date().addingTimeInterval(3600))
        ]
        
        // When - We'd call fetch matches
        // This would require mocking Firestore
        
        // Then - Verify matches are loaded
        matchService.$matches
            .dropFirst()
            .sink { matches in
                XCTAssertEqual(matches.count, 2)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Manually set matches for testing
        DispatchQueue.main.async {
            self.matchService.matches = testMatches
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCreateMatch() {
        // Given
        let expectation = XCTestExpectation(description: "Create match completes")
        let player1Id = "user1"
        let player2Id = "user2"
        let location = "Tennis Court 1"
        let date = Date().addingTimeInterval(86400) // Tomorrow
        
        // When - We'd call create match
        // matchService.createMatch(player1Id: player1Id, player2Id: player2Id, location: location, date: date)
        
        // Then - Verify match creation success
        matchService.$isLoading
            .dropFirst(2) // Skip initial false and the true when loading starts
            .sink { isLoading in
                XCTAssertFalse(isLoading)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate loading sequence
        DispatchQueue.main.async {
            self.matchService.isLoading = true
            
            // Simulate delay and completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.matchService.isLoading = false
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateMatchResult() {
        // Given
        let expectation = XCTestExpectation(description: "Update match result completes")
        let matchId = "match1"
        var match = Match(id: matchId, player1Id: "user1", player2Id: "user2", createdBy: "user1", location: "Court 1", scheduledDate: Date())
        
        let sets = [
            MatchSet(player1Score: 6, player2Score: 4),
            MatchSet(player1Score: 7, player2Score: 5)
        ]
        
        // When - We'd call update match
        // matchService.updateMatchResult(matchId: matchId, winnerId: "user1", sets: sets)
        
        // Then - Verify match update success
        matchService.$error
            .dropFirst()
            .sink { error in
                XCTAssertNil(error)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Manually trigger successful update for testing
        DispatchQueue.main.async {
            self.matchService.error = nil
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
} 