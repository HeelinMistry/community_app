//
//  MatchDetailsViewModelTests.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/05/14.
//

import XCTest
import Combine
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class MatchDetailsViewModelTests: XCTestCase {
    private var sut: MatchDetailsViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: MatchUseCasesProviderMock!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockProvider = .init()
        mockRouter = .init()
        cancellables = []
        sut = .init(useCases: mockProvider, router: mockRouter, match_id: "test_match_id_123")
    }
    
    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
        cancellables = nil // Release cancellables
        super.tearDown()
    }
    
    func testMatchDetails_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse: MatchDetailResponse = .init()
        mockProvider.mockUseCases.matchDetailsResult = .success(expectedResponse)
        
        // Act
        sut.matchDetail()
        
        // Wait for the Task to complete
        // We use a small delay or Task.yield since loginAttempt creates a detached Task
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .success(let response) = sut.state {
            XCTAssertTrue(response == expectedResponse)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }
    
    func testMatchDetails_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockUseCases.matchDetailsResult = .failure(error)
        
        // Act
        sut.matchDetail()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state")
        }
    }
    
    func testMatchParticipation_WhenTapped_SetsSuccessState() async {
        // Arrange
        // 1. Set up initial match details, explicitly showing not joined
        let initialDetail: MatchDetailResponse = .init(is_joined: false)
        mockProvider.mockUseCases.matchDetailsResult = .success(initialDetail)
        
        // Act - Fetch initial match details
        sut.matchDetail()
        // Wait for the matchDetail() Task to complete and update the state
        try? await Task.sleep(nanoseconds: 200_000_000) // Increased sleep duration for robustness
        
        // Optional: Assert initial state if desired for stronger test (precondition check)
        if case .success(let response) = sut.state {
            XCTAssertFalse(response.is_joined, "Precondition: Match should initially be not joined.")
        } else {
            XCTFail("Expected .success state after initial matchDetail() call, got \(sut.state)")
            return // Stop the test early if precondition fails
        }
        
        // Arrange - Set up the mock response for toggling participation
        let expectedParticipationResponse: ParticipationResponse = .init(is_joined: true)
        mockProvider.mockUseCases.participationResult = .success(expectedParticipationResponse)
        
        // Act - Toggle match participation
        sut.toggleMatchParticipation()
        // Wait for the toggle_match_participation() Task to complete and update the state
        try? await Task.sleep(nanoseconds: 200_000_000) // Increased sleep duration for robustness
        
        // Assert - Verify the final state after toggling
        if case .success(let finalResponse) = sut.state {
            XCTAssertTrue(finalResponse.is_joined == expectedParticipationResponse.is_joined, "Expected is_joined to be true after toggling participation.")
        } else {
            XCTFail("Expected .success state after toggle_match_participation() call, got \(sut.state)")
        }
    }
    
    func testMatchParticipation_WhenFails_SetsErrorState() async {
        // Arrange - Set up initial match details successfully
        let initialDetail: MatchDetailResponse = .init(is_joined: false)
        mockProvider.mockUseCases.matchDetailsResult = .success(initialDetail)

        // Act - Fetch initial match details
        sut.matchDetail()
        // Wait for the matchDetail() Task to complete and update the state
        try? await Task.sleep(nanoseconds: 200_000_000) // Increased sleep duration for robustness

        // Precondition check: Ensure the ViewModel is in a success state before attempting participation
        guard case .success(let response) = sut.state else {
            XCTFail("Expected .success state after initial matchDetail() call, got \(sut.state)")
            return
        }
        XCTAssertFalse(response.is_joined, "Precondition: Match should initially be not joined.")

        // Arrange - Set up the mock response for toggling participation to fail
        let errorMessage = "Participation Failed" 
        let error = NSError(domain: "MatchParticipation", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockUseCases.participationResult = .failure(error)
    
        // Act - Toggle match participation, expecting it to fail
        sut.toggleMatchParticipation()
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert - Verify the final state is an error
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage, "Expected the error message to match.")
        } else {
            XCTFail("Expected .error state after toggle_match_participation() failed, but got \(sut.state)")
        }
    }
    
    func testMatchCancellation_WhenTapped_SetsSuccessState() async {
        // Arrange
        // 1. Set up initial match details, explicitly showing not cancelled
        let initialDetail: MatchDetailResponse = .init(is_cancelled: false)
        mockProvider.mockUseCases.matchDetailsResult = .success(initialDetail)
        
        // Act - Fetch initial match details
        sut.matchDetail()
        // Wait for the matchDetail() Task to complete and update the state
        try? await Task.sleep(nanoseconds: 200_000_000) // Increased sleep duration for robustness
        
        // Optional: Assert initial state if desired for stronger test (precondition check)
        if case .success(let response) = sut.state {
            XCTAssertFalse(response.is_cancelled, "Precondition: Match should initially be not cancelled.")
        } else {
            XCTFail("Expected .success state after initial matchDetail() call, got \(sut.state)")
            return // Stop the test early if precondition fails
        }
        
        // Arrange - Set up the mock response for toggling cancellation
        let expectedCancellationResponse: CancellationResponse = .init(is_cancelled: true)
        mockProvider.mockUseCases.cancellationResult = .success(expectedCancellationResponse)
        
        // Act - Toggle match cancellation
        sut.toggleMatchCancellation()
        // Wait for the toggle_match_cancellation() Task to complete and update the state
        try? await Task.sleep(nanoseconds: 200_000_000) // Increased sleep duration for robustness
        
        // Assert - Verify the final state after toggling
        if case .success(let finalResponse) = sut.state {
            XCTAssertTrue(finalResponse.is_cancelled, "Expected is_cancelled to be true after toggling cancellation.")
        } else {
            XCTFail("Expected .success state after toggle_match_cancellation() call, got \(sut.state)")
        }
    }
    
    func testMatchCancellationWhenFails_SetsErrorState() async {
        // Arrange - Set up initial match details successfully
        let initialDetail: MatchDetailResponse = .init(is_cancelled: false)
        mockProvider.mockUseCases.matchDetailsResult = .success(initialDetail)

        // Act - Fetch initial match details
        sut.matchDetail()
        // Wait for the matchDetail() Task to complete and update the state
        try? await Task.sleep(nanoseconds: 200_000_000) // Increased sleep duration for robustness

        // Precondition check: Ensure the ViewModel is in a success state before attempting cancellation
        guard case .success(let response) = sut.state else {
            XCTFail("Expected .success state after initial matchDetail() call, got \(sut.state)")
            return
        }
        XCTAssertFalse(response.is_cancelled, "Precondition: Match should initially be not cancelled.")

        // Arrange - Set up the mock response for toggling cancellation to fail
        let errorMessage = "Cancellation Failed"
        let error = NSError(domain: "MatchCancellation", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockUseCases.cancellationResult = .failure(error)
    
        // Act - Toggle match cancellation, expecting it to fail
        sut.toggleMatchCancellation()
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Assert - Verify the final state is an error
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage, "Expected the error message to match.")
        } else {
            XCTFail("Expected .error state after toggle_match_cancellation() failed, but got \(sut.state)")
        }
    }
}
