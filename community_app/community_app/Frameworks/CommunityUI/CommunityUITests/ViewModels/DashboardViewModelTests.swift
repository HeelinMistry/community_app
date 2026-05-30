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
    
    // Replicate the formatter used in DashboardViewModel for consistent date string handling
    private static let testIsoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
    
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
    
    func testMatches_WhenFails_SetsErrorState() async {
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
    
    func testCreateMatch_WhenTapped_RoutesNavigation() async {
        sut.createMatchTapped()
        
        XCTAssertEqual(mockRouter.sheet, .createMatch)
    }
    
    func testUpcomingMatches_idleState_returnsEmpty() {
        XCTAssert(sut.upcomingMatches.isEmpty)
    }

    func testHistoryMatches_idleState_returnsEmpty() {
        XCTAssert(sut.historyMatches.isEmpty)
    }
    
    func testMatches_successState_returnsFiltered() async {
        let futureDate = Date.now.addingTimeInterval(3600) 
        let futureDate2 = Date.now.addingTimeInterval(7200)
        let pastDate = Date.now.addingTimeInterval(-3600)
        let pastDate2 = Date.now.addingTimeInterval(-7200)
        
        // Use the same ISO8601DateFormatter to format the date string
        let formattedFutureDateString = Self.testIsoDateFormatter.string(from: futureDate)
        let formattedFutureDateString2 = Self.testIsoDateFormatter.string(from: futureDate2)
        let formattedPastDateString = Self.testIsoDateFormatter.string(from: pastDate)
        let formattedPastDateString2 = Self.testIsoDateFormatter.string(from: pastDate2)
        
        let expectedResponse: Matches = [
            .init(start_datetime: formattedPastDateString),
            .init(start_datetime: formattedPastDateString2),
            .init(start_datetime: formattedFutureDateString),
            .init(start_datetime: formattedFutureDateString2)
        ]
        mockProvider.mockUseCases.matchResult = .success(expectedResponse)
        
        sut.matchFeed()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssert(sut.upcomingMatches.count == 2)
        XCTAssert(sut.historyMatches.count == 2)
    }

}
