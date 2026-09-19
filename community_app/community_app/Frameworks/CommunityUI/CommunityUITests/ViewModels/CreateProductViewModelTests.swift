//
//  CreateProductViewModelTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/09/19.
//

import XCTest
import Combine
import CoreLocation
import MapKit
import UIKit
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class CreateProductViewModelTests: XCTestCase {
    private var sut: CreateProductViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: ProductUseCasesProviderMock!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockProvider = .init()
        mockRouter = .init()
        cancellables = []
        sut = .init(useCases: mockProvider, router: mockRouter)
    }

    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
        cancellables = nil
        super.tearDown()
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

    func testIsFormValid_WhenStepIsMissing_SetsGeneralError() {
        // Act
        let isValid = sut.isFormValid()

        // Assert
        XCTAssertFalse(isValid)
        XCTAssertEqual(
            sut.validationErrors["general"],
            "Validation step could not be determined."
        )
    }

    func testIsFormValid_WhenStepOneIsIncomplete_SetsRequiredFieldErrors() {
        // Act
        let isValid = sut.isFormValid(step: 1)

        // Assert
        XCTAssertFalse(isValid)
        XCTAssertEqual(sut.validationErrors["title"], "Title is required")
        XCTAssertEqual(sut.validationErrors["description"], "Description is required")
    }

    func testIsFormValid_WhenEachStepIsComplete_ReturnsTrue() {
        // Arrange
        sut.title = "Fresh Produce"
        sut.description = "Locally grown seasonal vegetables."
        sut.chosenTags = ["vegetables"]
        sut.productMarkerLocation = CLLocationCoordinate2D(
            latitude: -25.7479,
            longitude: 28.2293
        )

        // Act & Assert
        XCTAssertTrue(sut.isFormValid(step: 1))
        XCTAssertTrue(sut.isFormValid(step: 2))
        XCTAssertTrue(sut.isFormValid(step: 3))
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    func testServiceRadius_WhenChanged_ClearsProductMarkerLocation() {
        // Arrange
        sut.productMarkerLocation = CLLocationCoordinate2D(
            latitude: -25.7479,
            longitude: 28.2293
        )

        // Act
        sut.service_radius = 2_000

        // Assert
        XCTAssertNil(sut.productMarkerLocation)
    }

    func testHandleImageSelection_WhenSuccessful_SetsDetectedTagsAndReturnsToIdle() async {
        // Arrange
        let expectedTags = ["vegetables", "organic"]
        mockProvider.mockProductUseCases.classifyResult = .success(
            (title: "Fresh Produce", tags: expectedTags)
        )

        // Act
        sut.handleImageSelection(images: [UIImage()])
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(sut.detectedTags, expectedTags)
        XCTAssertEqual(sut.state, .idle)
    }

    func testHandleImageSelection_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Unable to classify image."
        let error = NSError(
            domain: "ImageClassification",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        mockProvider.mockProductUseCases.classifyResult = .failure(error)

        // Act
        sut.handleImageSelection(images: [UIImage()])
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func testHandleImageSelection_WhenImagesAreEmpty_DoesNotChangeState() {
        // Act
        sut.handleImageSelection(images: [])

        // Assert
        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.detectedTags.isEmpty)
    }

    func testAdvertise_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse = AdvertiseProductResponse(product_id: "product_123")
        mockProvider.mockProductUseCases.createProductResult = .success(expectedResponse)
        mockProvider.mockProductUseCases.productImagesResult = .success(
            ProductImagesResponse(images: [])
        )
        sut.title = "Fresh Produce"
        sut.description = "Locally grown seasonal vegetables."
        sut.chosenTags = ["vegetables"]
        sut.productMarkerLocation = CLLocationCoordinate2D(
            latitude: -25.7479,
            longitude: 28.2293
        )

        // Act
        sut.advertise()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        if case .success(let response) = sut.state {
            XCTAssertEqual(response, expectedResponse)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }

    func testAdvertise_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Unable to create product."
        let error = NSError(
            domain: "CreateProduct",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        mockProvider.mockProductUseCases.createProductResult = .failure(error)
        sut.productMarkerLocation = CLLocationCoordinate2D(
            latitude: -25.7479,
            longitude: 28.2293
        )

        // Act
        sut.advertise()
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

    func testSelectedImagesAndChosenTags_WhenRemoved_UpdatesCollections() {
        // Arrange
        let firstImage = UIImage()
        let secondImage = UIImage()
        sut.selectedImages = [firstImage, secondImage]
        sut.chosenTags = ["vegetables", "organic"]

        // Act
        sut.removeSelectedImage(at: 0)
        sut.removeChosenTag("vegetables")

        // Assert
        XCTAssertTrue(sut.hasSelectedImages)
        XCTAssertEqual(sut.selectedImages.count, 1)
        XCTAssertEqual(sut.chosenTags, ["organic"])
    }
}

private final class ProductUseCasesProviderMock: ProductUseCasesProvider, @unchecked Sendable {
    let mockProductUseCases = ProductUseCasesMock()
    let locationMock = LocationServiceMock()

    var products: any ProductUseCasesProtocol {
        mockProductUseCases
    }

    var location: any LocationProtocol {
        locationMock
    }
}
