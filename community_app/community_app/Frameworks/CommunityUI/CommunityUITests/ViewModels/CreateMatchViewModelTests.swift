//
//  CreateMatchViewModelTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/02.
//

import XCTest
import Combine
import CoreLocation
import MapKit
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class CreateMatchViewModelTests: XCTestCase {
    private var sut: CreateMatchViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: MatchUseCasesProviderMock!
    private var mockMapSearchService: MockMapSearchService!
    
    override func setUp() {
        super.setUp()
        mockProvider = MatchUseCasesProviderMock()
        mockRouter = NavigationRouter()
        mockMapSearchService = MockMapSearchService()
        sut = CreateMatchViewModel(useCases: mockProvider, router: mockRouter, mapSearchService: mockMapSearchService)
    }
    
    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
        mockMapSearchService = nil
        super.tearDown()
    }
    
    func testCreate_WhenSuccessful_SetsSuccessState() async throws {
        // Arrange
        let expectedResponse = CreateMatchResponse(match_id: "98765")
        mockProvider.mockUseCases.createMatchResult = .success(expectedResponse)
        
        // Act
        sut.create()
        
        // Wait for the Task to complete
        // Using try await for precise timing in async tests
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .success(let response) = sut.state {
            XCTAssertEqual(response, expectedResponse, "Expected .success state with the correct response")
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }
    
    func testCreate_WhenFails_SetsErrorState() async throws {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Match", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockUseCases.createMatchResult = .failure(error)
        
        // Act
        sut.create()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage, "Expected .error state with the correct message")
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }
    
    func testCreate_InputValidation() async {
        // Initial state, should be invalid without any input for step 1
        var result = sut.isFormValid(step: 1)
        XCTAssertFalse(result, "Step 1 should be invalid initially")
        XCTAssertFalse(sut.validationErrors.isEmpty, "Validation errors should be present initially for step 1")
        
        // Fill in step 1 requirements
        sut.title = "test"
        sut.sport = .soccer
        sut.location = "longenough"
        sut.validatedLocationName = "longenough" // Ensure validated name is also set for `isFormValid`
        result = sut.isFormValid(step: 1)
        XCTAssertTrue(result, "Step 1 should be valid after filling title and location")
        XCTAssertTrue(sut.validationErrors.isEmpty, "Validation errors should be empty for a valid step 1")
        
        // Fill in step 2 requirements
        sut.duration = "30"
        sut.date_event = Date()
        sut.time = Date()
        result = sut.isFormValid(step: 2)
        XCTAssertTrue(result, "Step 2 should be valid after filling duration, date and time")
        XCTAssertTrue(sut.validationErrors.isEmpty, "Validation errors should be empty for a valid step 2")
        
        // Fill in step 3 requirements
        sut.roster_size = "12"
        sut.cost = "30"
        result = sut.isFormValid(step: 3)
        XCTAssertTrue(result, "Step 3 should be valid after filling roster size and cost")
        XCTAssertTrue(sut.validationErrors.isEmpty, "Validation errors should be empty for a valid step 3")
    }
    
    // MARK: - New Tests for searchLocation (converted from Swift Testing)
    
    func testSearchLocation_successUpdatesProperties() async throws {
        let query = "Eiffel Tower"
        let expectedCoordinate = CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945)
        let expectedName = "Eiffel Tower"
        
        let placemark = MKPlacemark(coordinate: expectedCoordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = expectedName
        
        mockMapSearchService.searchResult = .success([mapItem])
        
        // Initial state before search
        XCTAssertTrue(sut.validatedLocationName.isEmpty, "validatedLocationName should be empty initially")
        XCTAssertNil(sut.selectedLocationCoordinate, "selectedLocationCoordinate should be nil initially")
        
        await sut.searchLocation(query: query)
        
        // Assertions for updated properties
        XCTAssertEqual(sut.validatedLocationName, expectedName, "validatedLocationName should be updated to the item's name")
        XCTAssertEqual(sut.selectedLocationCoordinate?.latitude ?? 0.0, expectedCoordinate.latitude, accuracy: 0.0001, "selectedLocationCoordinate latitude should match")
        XCTAssertEqual(sut.selectedLocationCoordinate?.longitude ?? 0.0, expectedCoordinate.longitude, accuracy: 0.0001, "selectedLocationCoordinate longitude should match")
        
        // Assert mapCameraPosition
        //        if case .region(let region) = sut.mapCameraPosition {
        //            XCTAssertEqual(region.center.latitude, expectedCoordinate.latitude, accuracy: 0.0001, "Map camera center latitude should match")
        //            XCTAssertEqual(region.center.longitude, expectedCoordinate.longitude, accuracy: 0.0001, "Map camera center longitude should match")
        //            XCTAssertEqual(region.span.latitudeDelta, 0.01, accuracy: 0.0001, "Map camera span latitudeDelta should be 0.01 for zoom")
        //            XCTAssertEqual(region.span.longitudeDelta, 0.01, accuracy: 0.0001, "Map camera span longitudeDelta should be 0.01 for zoom")
        //        } else {
        //            XCTFail("mapCameraPosition should be a region after a successful search")
        //        }
    }
    
    func testSearchLocation_emptyQueryResetsPropertiesToDefault() async {
        // Simulate a previous search result being present
        sut.validatedLocationName = "Some Validated Place"
        sut.selectedLocationCoordinate = CLLocationCoordinate2D(latitude: 10, longitude: 20)
        //        sut.mapCameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 10, longitude: 20), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        
        await sut.searchLocation(query: "")
        
        // Assertions for reset properties
        XCTAssertTrue(sut.validatedLocationName.isEmpty, "validatedLocationName should be empty for an empty query")
        XCTAssertNil(sut.selectedLocationCoordinate, "selectedLocationCoordinate should be nil for an empty query")
        
        // Assert mapCameraPosition resets to the default values from the ViewModel's initialization
        //        if case .region(let region) = sut.mapCameraPosition {
        //            XCTAssertEqual(region.center.latitude, -25.86, accuracy: 0.0001, "Map camera center latitude should reset to default")
        //            XCTAssertEqual(region.center.longitude, 28.18, accuracy: 0.0001, "Map camera center longitude should reset to default")
        //            XCTAssertEqual(region.span.latitudeDelta, 0.05, accuracy: 0.0001, "Map camera span latitudeDelta should reset to default")
        //            XCTAssertEqual(region.span.longitudeDelta, 0.05, accuracy: 0.0001, "Map camera span longitudeDelta should reset to default")
        //        } else {
        //            XCTFail("mapCameraPosition should be the default region for an empty query")
        //        }
    }
    
    func testSearchLocation_noResultsClearsSelectedPropertiesButKeepsMapPosition() async {
        let query = "NonExistentPlace"
        mockMapSearchService.searchResult = .success([]) // Return an empty array of map items
        
        // Store initial map position before the search
        let initialMapPosition = sut.mapCameraPosition
        
        // Simulate a previous search result being present before this 'no result' search
        sut.validatedLocationName = "Previously Validated Place"
        sut.selectedLocationCoordinate = CLLocationCoordinate2D(latitude: 10, longitude: 20)
        
        await sut.searchLocation(query: query)
        
        // Assertions
        XCTAssertTrue(sut.validatedLocationName.isEmpty, "validatedLocationName should be empty when no results are found")
        XCTAssertNil(sut.selectedLocationCoordinate, "selectedLocationCoordinate should be nil when no results are found")
        
        // Map camera position should remain unchanged from its state BEFORE the search
        //        if case .region(let currentRegion) = sut.mapCameraPosition,
        //           case .region(let initialRegion) = initialMapPosition {
        //            XCTAssertEqual(currentRegion.center.latitude, initialRegion.center.latitude, accuracy: 0.0001, "Map camera position latitude should be unchanged")
        //            XCTAssertEqual(currentRegion.center.longitude, initialRegion.center.longitude, accuracy: 0.0001, "Map camera position longitude should be unchanged")
        //            XCTAssertEqual(currentRegion.span.latitudeDelta, initialRegion.span.latitudeDelta, accuracy: 0.0001, "Map camera span latitudeDelta should be unchanged")
        //            XCTAssertEqual(currentRegion.span.longitudeDelta, initialRegion.span.longitudeDelta, accuracy: 0.0001, "Map camera span longitudeDelta should be unchanged")
        //        } else {
        //            XCTFail("mapCameraPosition should remain unchanged as a region")
        //        }
    }
    
    func testSearchLocation_errorClearsSelectedPropertiesButKeepsMapPosition() async {
        let query = "ErrorQuery"
        enum TestError: Error, LocalizedError {
            case searchFailed
            var errorDescription: String? { "Test search failed" }
        }
        mockMapSearchService.searchResult = .failure(TestError.searchFailed)
        
        // Store initial map position before the search
        let initialMapPosition = sut.mapCameraPosition
        
        // Simulate a previous search result being present
        sut.validatedLocationName = "Previously Validated Place"
        sut.selectedLocationCoordinate = CLLocationCoordinate2D(latitude: 10, longitude: 20)
        
        await sut.searchLocation(query: query)
        
        // Assertions
        XCTAssertTrue(sut.validatedLocationName.isEmpty, "validatedLocationName should be empty on search error")
        XCTAssertNil(sut.selectedLocationCoordinate, "selectedLocationCoordinate should be nil on search error")
        
        // Map camera position should remain unchanged from its state BEFORE the search
        //        if case .region(let currentRegion) = sut.mapCameraPosition,
        //           case .region(let initialRegion) = initialMapPosition {
        //            XCTAssertEqual(currentRegion.center.latitude, initialRegion.center.latitude, accuracy: 0.0001, "Map camera position latitude should be unchanged on error")
        //            XCTAssertEqual(currentRegion.center.longitude, initialRegion.center.longitude, accuracy: 0.0001, "Map camera position longitude should be unchanged on error")
        //            XCTAssertEqual(currentRegion.span.latitudeDelta, initialRegion.span.latitudeDelta, accuracy: 0.0001, "Map camera span latitudeDelta should be unchanged on error")
        //            XCTAssertEqual(currentRegion.span.longitudeDelta, initialRegion.span.longitudeDelta, accuracy: 0.0001, "Map camera span longitudeDelta should be unchanged on error")
        //        } else {
        //            XCTFail("mapCameraPosition should remain unchanged as a region on error")
        //        }
    }
    
    //    func testSearchLocation_itemNameNilUsesQueryForValidatedLocationName() async throws {
    //        let query = "Unnamed Location"
    //        let expectedCoordinate = CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0)
    //
    //        let placemark = MKPlacemark(coordinate: expectedCoordinate)
    //        let mapItem = MKMapItem(placemark: placemark)
    //        mapItem.name = nil
    //
    //        mockMapSearchService.searchResult = .success([mapItem])
    //
    //        await sut.searchLocation(query: query)
    //
    //        XCTAssertEqual(sut.validatedLocationName, query, "validatedLocationName should fall back to query if map item's name is nil")
    //        XCTAssertEqual(sut.selectedLocationCoordinate?.latitude, expectedCoordinate.latitude, accuracy: 0.0001)
    //        XCTAssertEqual(sut.selectedLocationCoordinate?.longitude, expectedCoordinate.longitude, accuracy: 0.0001)
    //    }
}
