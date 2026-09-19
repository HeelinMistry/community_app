//
//  ProductUseCasesTests.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/09/19.
//

import XCTest
@testable import CommunityCore

final class ProductUseCasesTests: XCTestCase {

    private var sut: ProductUseCases!
    private var mockRepository: ProductRepositoryMock!
    private var mockImageCache: ImageCacheMock!

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockImageCache = nil
        super.tearDown()
    }

    func testClassify_WhenSuccessful_ReturnsSuccessResponse() async throws {
        let (sut, mockRepository, _) = makeSUT()
        let expectedResponse = (title: "Fresh Produce", tags: ["food", "organic"])
        await mockRepository.setClassifyResult(.success(expectedResponse))

        let response = try await sut.classify([])

        XCTAssertEqual(response.title, expectedResponse.title)
        XCTAssertEqual(response.tags, expectedResponse.tags)
    }

    func testClassify_WhenRepositoryThrowsError_ThrowsSameError() async {
        let (sut, mockRepository, _) = makeSUT()
        await mockRepository.setClassifyResult(.failure(networkError))

        await assertNetworkError {
            _ = try await sut.classify([])
        }
    }

    func testAdvertise_WhenSuccessful_ReturnsSuccessResponse() async throws {
        let (sut, mockRepository, _) = makeSUT()
        let expectedResponse = AdvertiseProductResponse(product_id: "product_1")
        await mockRepository.setCreateResult(.success(expectedResponse))

        let response = try await sut.advertise(advertiseRequest)

        XCTAssertEqual(response, expectedResponse)
    }

    func testAdvertise_WhenRepositoryThrowsError_ThrowsSameError() async {
        let (sut, mockRepository, _) = makeSUT()
        await mockRepository.setCreateResult(.failure(networkError))

        await assertNetworkError {
            _ = try await sut.advertise(advertiseRequest)
        }
    }

    func testNearbyProducts_WhenSuccessful_ReturnsSuccessResponse() async throws {
        let (sut, mockRepository, _) = makeSUT()
        let expectedResponse: Products = [productResponse]
        await mockRepository.setNearbyProductsResult(.success(expectedResponse))

        let response = try await sut.userNearbyProducts(locationRequest)

        XCTAssertEqual(response, expectedResponse)
    }

    func testNearbyProducts_WhenRepositoryThrowsError_ThrowsSameError() async {
        let (sut, mockRepository, _) = makeSUT()
        await mockRepository.setNearbyProductsResult(.failure(networkError))

        await assertNetworkError {
            _ = try await sut.userNearbyProducts(locationRequest)
        }
    }

    func testLink_WhenSuccessful_ReturnsSuccessResponse() async throws {
        let (sut, mockRepository, _) = makeSUT()
        let expectedResponse = ProductImagesResponse(images: ["product_1.jpg"])
        await mockRepository.setUploadResult(.success(expectedResponse))

        let response = try await sut.link(productId: "product_1", images: [])

        XCTAssertEqual(response, expectedResponse)
    }

    func testLink_WhenRepositoryThrowsError_ThrowsSameError() async {
        let (sut, mockRepository, _) = makeSUT()
        await mockRepository.setUploadResult(.failure(networkError))

        await assertNetworkError {
            _ = try await sut.link(productId: "product_1", images: [])
        }
    }

    func testSelectedProduct_WhenSuccessful_ReturnsSuccessResponse() async throws {
        let (sut, mockRepository, _) = makeSUT()
        let expectedResponse = ProductDetailResponse(id: "product_1")
        await mockRepository.setProductDetailsResult(.success(expectedResponse))

        let response = try await sut.selectedProduct(DetailRequest("product_1"))

        XCTAssertEqual(response, expectedResponse)
    }

    func testSelectedProduct_WhenRepositoryThrowsError_ThrowsSameError() async {
        let (sut, mockRepository, _) = makeSUT()
        await mockRepository.setProductDetailsResult(.failure(networkError))

        await assertNetworkError {
            _ = try await sut.selectedProduct(DetailRequest("product_1"))
        }
    }

    func testImageDownloadable_WhenSuccessful_ReturnsCachedImageURL() async throws {
        let (sut, _, mockImageCache) = makeSUT()
        let expectedURL = URL(fileURLWithPath: "/tmp/product_1.jpg")
        await mockImageCache.setCachedImageURLResult(.success(expectedURL))

        let response = try await sut.imageDownloadable(url: "https://example.com/product_1.jpg")

        XCTAssertEqual(response, expectedURL)
    }

    func testImageDownloadable_WhenCacheThrowsError_ThrowsSameError() async {
        let (sut, _, mockImageCache) = makeSUT()
        await mockImageCache.setCachedImageURLResult(.failure(networkError))

        await assertNetworkError {
            _ = try await sut.imageDownloadable(url: "https://example.com/product_1.jpg")
        }
    }

    private func makeSUT() -> (ProductUseCases, ProductRepositoryMock, ImageCacheMock) {
        let mockRepository = ProductRepositoryMock()
        let mockImageCache = ImageCacheMock()
        let sut = ProductUseCases(product: mockRepository, imageCache: mockImageCache)
        return (sut, mockRepository, mockImageCache)
    }

    private var networkError: NSError {
        NSError(domain: "NetworkError", code: 401, userInfo: nil)
    }

    private var advertiseRequest: AdvertiseProductRequest {
        AdvertiseProductRequest(
            title: "Fresh Produce",
            description: "Locally grown vegetables",
            tags: ["food", "organic"],
            latitude: -25.7479,
            longitude: 28.2293,
            service_radius: 5
        )
    }

    private var locationRequest: LocationRequest {
        LocationRequest(lat: -25.7479, lon: 28.2293)
    }

    private var productResponse: ProductResponse {
        ProductResponse(
            id: "product_1",
            user_id: "user_1",
            title: "Fresh Produce",
            description: "Locally grown vegetables",
            tags: ["food", "organic"],
            distance_km: 2.5,
            latitude: -25.7479,
            longitude: 28.2293,
            is_creator: false,
            is_available: true
        )
    }

    private func assertNetworkError(
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
}
