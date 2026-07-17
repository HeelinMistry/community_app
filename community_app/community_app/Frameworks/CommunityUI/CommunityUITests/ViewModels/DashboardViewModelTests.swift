//
//  DashboardViewModelTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import XCTest
import Combine
import CoreLocation
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class DashboardViewModelTests: XCTestCase {
    private var sut: DashboardViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: DashboardUseCasesProviderMock!
    
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
        
        // Provide a default history match in setUp for general cases
        let pastDateForSetup = Date.now.addingTimeInterval(-3600) // 1 hour ago
        let formattedPastDateStringForSetup = Self.testIsoDateFormatter.string(from: pastDateForSetup)
        let expectedResponseForSetup: Matches = [.init(start_datetime: formattedPastDateStringForSetup)]
        mockProvider.mockMatchUseCases.matchResult = .success(expectedResponseForSetup)
        
        let expectedLocation = CLLocation(latitude: -25.86, longitude: 28.18)
        mockProvider.locationMock.lastKnownLocation = expectedLocation
        
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
        let pastDate = Date.now.addingTimeInterval(-3600) // A date in the past (e.g., 1 hour ago)
        let formattedPastDateString = Self.testIsoDateFormatter.string(from: pastDate)
        
        let expectedResponse: Matches = [.init(start_datetime: formattedPastDateString)]
        mockProvider.mockMatchUseCases.matchResult = .success(expectedResponse)
        
        // Act
        sut.matchFeed()
        
        // Wait for the Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .success(let response) = sut.state {
            XCTAssertEqual(response.historyMatches.count, 1, "Expected 1 history match")
            XCTAssertEqual(response.upcomingMatches.count, 0, "Expected 0 upcoming matches") // Added for clarity
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }
    
    func testMatches_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockMatchUseCases.matchResult = .failure(error)
        
        // Act
        Task { @MainActor in
            sut.matchFeed()
        }
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
        // After setup, if matchFeed hasn't been called, upcoming should be empty.
        // If setUp always calls matchFeed with a past match, this test might need adjustment.
        // Assuming matchFeed is not implicitly called before this test runs or state is reset.
        XCTAssert(sut.dashboardModel.upcomingMatches.isEmpty)
    }

    func testHistoryMatches_idleState_returnsEmpty() {
        // Similar to upcomingMatches_idleState, depends on when matchFeed is called.
        // If setUp provides a history match, this test might fail as historyMatches won't be empty.
        // For truly idle state, you might need to ensure matchFeed is not called, or state is cleared.
        XCTAssert(sut.dashboardModel.historyMatches.isEmpty)
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
        mockProvider.mockMatchUseCases.matchResult = .success(expectedResponse)
        
        Task { @MainActor in
            sut.matchFeed()
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssert(sut.dashboardModel.upcomingMatches.count == 2)
        XCTAssert(sut.dashboardModel.historyMatches.count == 2)
    }
    
    func testNearbySuppliers_WhenSuccessful_SetsSuccessState() async throws {
        let expectedSupplier: Suppliers = [.init(
            id: "s_1231",
            user_id: "1231",
            business_name: "test_business",
            description: "Rotis",
            category: "Catering",
            distance_km: 10.0,
            latitude: -25.86,
            longitude: 28.18,
            is_creator: true
        )]
        mockProvider.mockSuppliersUseCases.supplierResult = .success(expectedSupplier)
        sut.nearbySuppliers()
        
        // Wait for the Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .success(let response) = sut.state {
            XCTAssertEqual(response.suppliers.count, 1, "Expected 1 supplier")
            XCTAssertEqual(response.suppliers.first?.latitude, -25.86)
            XCTAssertEqual(response.suppliers.first?.longitude, 28.18)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }

    func testNearbySuppliers_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockSuppliersUseCases.supplierResult = .failure(error)
        
        // Act
        Task { @MainActor in
            sut.nearbySuppliers()
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state")
        }
    }
}
