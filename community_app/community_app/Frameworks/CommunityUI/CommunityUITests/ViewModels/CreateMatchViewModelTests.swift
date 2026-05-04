//
//  CreateMatchViewModelTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/02.
//

import XCTest
import Combine
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class CreateMatchViewModelTests: XCTestCase {
    private var sut: CreateMatchViewModel!
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
    
    func testCreate_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse = CreateMatchResponse(match_id: "98765")
        mockProvider.mockUseCases.createMatchResult = .success(expectedResponse)
        
        // Act
        sut.create()
        
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
    
    func testCreate_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Match", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockUseCases.createMatchResult = .failure(error)
        
        // Act
        sut.create()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state")
        }
    }
    
    func testCreate_InputValidation() async {
        var result = sut.isFormValid
        XCTAssertFalse(result)
        XCTAssertFalse(sut.validationErrors.isEmpty)
        
        sut.title = "test"
        sut.sport = "test"
        sut.duration = "30"
        sut.date_event = "0987654567"
        sut.time = "longenough"
        sut.location = "longenough"
        sut.roster_size = "12"
        sut.cost = "30"
        result = sut.isFormValid
        XCTAssertTrue(result)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }
}
