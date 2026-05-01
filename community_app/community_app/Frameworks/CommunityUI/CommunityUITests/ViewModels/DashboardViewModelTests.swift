//
//  DashboardViewModelTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import XCTest
import Combine
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class DashboardViewModelTests: XCTestCase {
    private var sut: DashboardViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: MatchUseCasesProviderMock!
    
    override func setUp() {
        super.setUp()
        mockProvider = .init()
        mockRouter = .init()
        sut = .init(useCases: mockProvider, router: mockRouter)
    }
    
    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
        super.tearDown()
    }
    
    func testMatches_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse: Matches = [.init()]
        mockProvider.mockUseCases.matchResult = .success(expectedResponse)
        
        // Act
        sut.matchFeed()
        
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
    
    func testLogin_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockUseCases.matchResult = .failure(error)
        
        // Act
        sut.matchFeed()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state")
        }
    }
}
