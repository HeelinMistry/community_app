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
    
    override func setUp() {
        super.setUp()
        mockProvider = .init()
        mockRouter = .init()
        sut = .init(useCases: mockProvider, router: mockRouter, match_id: "")
    }
    
    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
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
    
//    func testMatchParticipation_WhenTapped() async {
//        sut.toggle_match_participation()
//        
//        XCTAssertEqual(mockRouter.sheet, .createMatch)
//    }
}
