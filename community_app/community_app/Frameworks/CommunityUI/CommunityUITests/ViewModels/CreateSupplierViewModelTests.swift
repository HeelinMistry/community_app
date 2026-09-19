//
//  CreateSupplierViewModelTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/09/19.
//

import XCTest
import Combine
import CoreLocation
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class CreateSupplierViewModelTests: XCTestCase {
    private var sut: CreateSupplierViewModel!
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
            router: mockRouter
        )
    }

    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
        cancellables = nil
        super.tearDown()
    }

    func testCreate_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse = CreateSupplierResponse(supplier_id: "test_supplier_id_123")
        mockProvider = .init(
            authorizationStatus: .authorizedWhenInUse,
            lastKnownLocation: CLLocation(latitude: -25.7479, longitude: 28.2293)
        )
        sut = .init(useCases: mockProvider, router: mockRouter)
        mockProvider.mockSupplierUseCases.createSupplierResult = .success(expectedResponse)
        sut.business_name = "Local Bakery"
        sut.description = "Freshly baked goods"
        sut.category = .homeLifestyle
        sut.service_radius = 5_000

        // Act
        sut.create()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        if case .success(let response) = sut.state {
            XCTAssertEqual(response, expectedResponse)
            XCTAssertNil(mockRouter.sheet)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }

    func testCreate_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Unable to create supplier"
        let error = NSError(
            domain: "CreateSupplier",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        mockProvider.mockSupplierUseCases.createSupplierResult = .failure(error)

        // Act
        sut.create()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
            XCTAssertEqual(
                sut.validationErrors["general"],
                "Failed to create match: \(errorMessage)"
            )
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func testIsFormValid_WhenRequiredFieldsAreMissing_ReturnsFalseWithErrors() {
        // Act
        let result = sut.isFormValid(step: 1)

        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(sut.validationErrors["business_name"], "Business name cannot be empty")
        XCTAssertEqual(sut.validationErrors["description"], "Description cannot be empty")
        XCTAssertEqual(
            sut.validationErrors["location"],
            "Location services are required. Please enable in Settings."
        )
    }

    func testIsFormValid_WhenFieldsAndLocationAreValid_ReturnsTrue() async {
        // Arrange
        mockProvider = .init(
            authorizationStatus: .authorizedWhenInUse,
            lastKnownLocation: CLLocation(latitude: -25.7479, longitude: 28.2293)
        )
        sut = .init(useCases: mockProvider, router: mockRouter)
        sut.business_name = "Local Bakery"
        sut.description = "Freshly baked goods"
        sut.service_radius = 5_000
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Act
        let result = sut.isFormValid(step: 1)

        // Assert
        XCTAssertTrue(result)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    func testRequestLocationAuthorization_WhenSuccessful_CallsServiceAndUpdatesStatus() async {
        // Arrange
        mockProvider.locationMock.authorizationStatus = .notDetermined
        mockProvider.locationMock.requestLocationAuthorizationResult = .success(())

        // Act
        await sut.requestLocationAuthorization()
        try? await Task.sleep(nanoseconds: 100_000_000)

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
}

private final class SupplierUseCasesProviderMock: SupplierUseCasesProvider, @unchecked Sendable {
    let mockSupplierUseCases = SupplierUseCasesMock()
    let locationMock: LocationServiceMock

    init(
        authorizationStatus: CLAuthorizationStatus? = .notDetermined,
        lastKnownLocation: CLLocation? = nil
    ) {
        locationMock = .init(
            authorizationStatus: authorizationStatus,
            lastKnownLocation: lastKnownLocation
        )
    }

    var suppliers: any SupplierUseCasesProtocol {
        mockSupplierUseCases
    }

    var location: any LocationProtocol {
        locationMock
    }
}
