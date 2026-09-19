//
//  SupplierDetailsViewModelTests.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/09/19.
//

import XCTest
import Combine
import CoreLocation
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class SupplierDetailsViewModelTests: XCTestCase {
    private var sut: SupplierDetailsViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: SupplierUseCasesProviderMock!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockProvider = .init()
        mockRouter = .init()
        cancellables = []
        sut = .init(
            useCases: mockProvider,
            router: mockRouter,
            supplier_id: "test_supplier_id_123"
        )
    }

    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
        cancellables = nil
        super.tearDown()
    }

    func testSupplierDetails_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse = SupplierDetailResponse(
            id: "test_supplier_id_123",
            business_name: "Local Bakery"
        )
        mockProvider.mockSupplierUseCases.selectedSupplierResult = .success(expectedResponse)

        // Act
        sut.supplierDetail()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        if case .success(let response) = sut.state {
            XCTAssertEqual(response, expectedResponse)
            XCTAssertEqual(sut.supplierDetailResponse, expectedResponse)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }

    func testSupplierDetails_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Supplier details unavailable"
        let error = NSError(
            domain: "SupplierDetails",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        mockProvider.mockSupplierUseCases.selectedSupplierResult = .failure(error)

        // Act
        sut.supplierDetail()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func testIsAuthorized_WhenAuthorizedAlways_ReturnsTrue() {
        // Arrange
        mockProvider.locationMock.authorizationStatus = .authorizedAlways

        // Act & Assert
        XCTAssertTrue(sut.isAuthorized)
    }

    func testIsAuthorized_WhenDenied_ReturnsFalse() {
        // Arrange
        mockProvider.locationMock.authorizationStatus = .denied

        // Act & Assert
        XCTAssertFalse(sut.isAuthorized)
    }

    func testRequestLocationAuthorization_WhenSuccessful_CallsServiceAndUpdatesStatus() async {
        // Arrange
        mockProvider.locationMock.authorizationStatus = .notDetermined
        mockProvider.locationMock.requestLocationAuthorizationResult = .success(())

        // Act
        await sut.requestLocationAuthorization()

        // Assert
        XCTAssertEqual(mockProvider.locationMock.requestLocationAuthorizationCallCount, 1)
        XCTAssertEqual(mockProvider.locationMock.authorizationStatus, .authorizedWhenInUse)
        XCTAssertTrue(sut.isAuthorized)
        if case .error = sut.state {
            XCTFail("ViewModel state should not be .error on successful authorization.")
        }
    }

    func testRequestLocationAuthorization_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Location authorization failed."
        let error = NSError(
            domain: "LocationError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        mockProvider.locationMock.requestLocationAuthorizationResult = .failure(error)

        // Act
        await sut.requestLocationAuthorization()

        // Assert
        XCTAssertEqual(mockProvider.locationMock.requestLocationAuthorizationCallCount, 1)
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func testShowDirectionsOnMap_WhenDetailsAndLocationAvailable_CallsService() async {
        // Arrange
        let expectedResponse = SupplierDetailResponse(
            business_name: "Local Bakery",
            latitude: -25.7479,
            longitude: 28.2293
        )
        mockProvider.mockSupplierUseCases.selectedSupplierResult = .success(expectedResponse)
        mockProvider.locationMock.lastKnownLocation = CLLocation(
            latitude: -25.85,
            longitude: 28.21
        )

        // Act
        sut.supplierDetail()
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.showDirectionsOnMap()

        // Assert
        XCTAssertEqual(
            mockProvider.locationMock.openedDirectionsCoordinate?.latitude,
            expectedResponse.latitude
        )
        XCTAssertEqual(
            mockProvider.locationMock.openedDirectionsCoordinate?.longitude,
            expectedResponse.longitude
        )
        XCTAssertEqual(
            mockProvider.locationMock.openedDirectionsName,
            expectedResponse.business_name
        )
    }

    func testShowDirectionsOnMap_WhenLocationMissing_SetsErrorState() {
        // Arrange
        mockProvider.locationMock.lastKnownLocation = nil

        // Act
        sut.showDirectionsOnMap()

        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, "Your current location is not available.")
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func testShowDirectionsOnMap_WhenSupplierDetailsMissing_SetsErrorState() {
        // Arrange
        mockProvider.locationMock.lastKnownLocation = CLLocation(
            latitude: -25.85,
            longitude: 28.21
        )

        // Act
        sut.showDirectionsOnMap()

        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, "Supplier details not available.")
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }
}

private final class SupplierUseCasesProviderMock: SupplierUseCasesProvider, @unchecked Sendable {
    let mockSupplierUseCases = SupplierUseCasesMock()
    let locationMock = LocationServiceMock()

    var suppliers: any SupplierUseCasesProtocol {
        mockSupplierUseCases
    }

    var location: any LocationProtocol {
        locationMock
    }
}
