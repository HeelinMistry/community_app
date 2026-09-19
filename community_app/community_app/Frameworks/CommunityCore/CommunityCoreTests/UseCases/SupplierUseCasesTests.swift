//
//  SupplierUseCasesTests.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/09/19.
//

import XCTest
@testable import CommunityCore

final class SupplierUseCasesTests: XCTestCase {

    private var sut: SupplierUseCases!
    private var mockRepository: SupplierRepositoryMock!

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testNearbySuppliers_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = SupplierRepositoryMock()

        let expectedResponse: Suppliers = [
            .init(
                id: "supplier_1",
                user_id: "user_1",
                business_name: "Sample Supplier",
                description: "A supplier description",
                category: "Services",
                distance_km: 2.5,
                latitude: -25.7479,
                longitude: 28.2293,
                is_creator: false
            )
        ]
        await mockRepository.setNearbySuppliersResult(
            .success(expectedResponse)
        )

        let sut = SupplierUseCases(supplier: mockRepository)
        let response = try await sut.userNearbySuppliers(.init(lat: -25.7479, lon: 28.2293))

        XCTAssertTrue(response == expectedResponse)
    }

    func testNearbySuppliers_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = SupplierRepositoryMock()

        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setNearbySuppliersResult(
            .failure(expectedError)
        )

        let sut = SupplierUseCases(supplier: mockRepository)
        do {
            _ = try await sut.userNearbySuppliers(.init(lat: -25.7479, lon: 28.2293))
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }

    func testCreateSupplier_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = SupplierRepositoryMock()

        let expectedResponse: CreateSupplierResponse = .init(supplier_id: "supplier_1")
        await mockRepository.setCreateSupplierResult(
            .success(expectedResponse)
        )

        let sut = SupplierUseCases(supplier: mockRepository)
        let response = try await sut.userCreateSupplier(
            .init(
                business_name: "Sample Supplier",
                description: "A supplier description",
                category: "Services",
                latitude: -25.7479,
                longitude: 28.2293,
                service_radius: 5
            )
        )

        XCTAssertTrue(response == expectedResponse)
    }

    func testCreateSupplier_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = SupplierRepositoryMock()

        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setCreateSupplierResult(
            .failure(expectedError)
        )

        let sut = SupplierUseCases(supplier: mockRepository)
        do {
            _ = try await sut.userCreateSupplier(
                .init(
                    business_name: "Sample Supplier",
                    description: "A supplier description",
                    category: "Services",
                    latitude: -25.7479,
                    longitude: 28.2293,
                    service_radius: 5
                )
            )
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }

    func testSupplierDetails_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = SupplierRepositoryMock()

        let expectedResponse: SupplierDetailResponse = .init()
        await mockRepository.setSupplierDetailResult(
            .success(expectedResponse)
        )

        let sut = SupplierUseCases(supplier: mockRepository)
        let response = try await sut.selectedSupplierDetails(.init("supplier_1"))

        XCTAssertTrue(response == expectedResponse)
    }

    func testSupplierDetails_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = SupplierRepositoryMock()

        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setSupplierDetailResult(
            .failure(expectedError)
        )

        let sut = SupplierUseCases(supplier: mockRepository)
        do {
            _ = try await sut.selectedSupplierDetails(.init("supplier_1"))
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
}
