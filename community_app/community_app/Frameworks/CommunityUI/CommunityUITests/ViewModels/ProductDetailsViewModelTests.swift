//
//  ProductDetailsViewModelTests.swift
//  CommunityUI
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
final class ProductDetailsViewModelTests: XCTestCase {
    private var sut: ProductDetailsViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: ProductDetailsUseCasesProviderMock!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockProvider = .init()
        mockRouter = .init()
        cancellables = []
        sut = .init(
            useCases: mockProvider,
            router: mockRouter,
            product_id: "test_product_id_123"
        )
    }

    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
        cancellables = nil
        super.tearDown()
    }

    func testProductDetails_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse = ProductDetailResponse(
            id: "test_product_id_123",
            title: "Fresh Produce",
            image_urls: []
        )
        mockProvider.mockProductUseCases.productDetailResult = .success(expectedResponse)

        // Act
        await sut.productDetail()

        // Assert
        if case .success(let response) = sut.state {
            XCTAssertEqual(response, expectedResponse)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
        XCTAssertTrue(sut.productImages.isEmpty)
    }

    func testProductDetails_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Product details unavailable"
        let error = NSError(
            domain: "ProductDetails",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        mockProvider.mockProductUseCases.productDetailResult = .failure(error)

        // Act
        await sut.productDetail()

        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func testProductDetails_WhenImageDownloadFails_SetsErrorState() async {
        // Arrange
        let expectedResponse = ProductDetailResponse(
            id: "test_product_id_123",
            image_urls: ["https://example.com/product.jpg"]
        )
        let errorMessage = "Unable to download product image."
        let error = NSError(
            domain: "ProductImage",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        mockProvider.mockProductUseCases.productDetailResult = .success(expectedResponse)
        mockProvider.mockProductUseCases.imageURL = .failure(error)

        // Act
        await sut.productDetail()

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

    func testIsFormValid_WhenRequiredFieldsAreMissing_SetsRequiredFieldErrors() {
        // Act
        let isValid = sut.isFormValid()

        // Assert
        XCTAssertFalse(isValid)
        XCTAssertEqual(sut.validationErrors["title"], "Title is required")
        XCTAssertEqual(sut.validationErrors["description"], "Description is required")
        XCTAssertEqual(sut.validationErrors["location"], "Location is required")
        XCTAssertEqual(sut.validationErrors["chosenTags"], "Tags are required")
    }

    func testIsFormValid_WhenRequiredFieldsAreProvided_ReturnsTrue() {
        // Arrange
        sut.title = "Fresh Produce"
        sut.description = "Locally grown seasonal vegetables."
        sut.chosenTags = ["vegetables"]
        sut.productMarkerLocation = CLLocationCoordinate2D(
            latitude: -25.7479,
            longitude: 28.2293
        )

        // Act & Assert
        XCTAssertTrue(sut.isFormValid())
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
        XCTAssertEqual(sut.selectedImages.count, 1)
        XCTAssertEqual(sut.chosenTags, ["organic"])
    }
}

private final class ProductDetailsUseCasesProviderMock: ProductUseCasesProvider, @unchecked Sendable {
    let mockProductUseCases = ProductUseCasesMock()
    let locationMock = LocationServiceMock()

    var products: any ProductUseCasesProtocol {
        mockProductUseCases
    }

    var location: any LocationProtocol {
        locationMock
    }
}
