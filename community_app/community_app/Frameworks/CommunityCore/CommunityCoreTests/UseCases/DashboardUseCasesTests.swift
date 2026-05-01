//
//  DashboardUseCasesTests.swift
//  CommunityCoreTests
//
//  Created by Heelin Mistry on 2026/04/30.
//

import XCTest
@testable import CommunityCore

final class DashboardUseCasesTests: XCTestCase {
    
    private var sut: DashboardUseCases!
    private var mockRepository: DashboardRepositoryMock!
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testMatchesExecute_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = DashboardRepositoryMock()
        
        let expectedResponse: Matches = [.init()]
        await mockRepository.setMatchResult(
            .success(expectedResponse)
        )
        
        let sut = DashboardUseCases(dashboard: mockRepository)
        let response = try await sut.userRelatedMatches()
        
        XCTAssertTrue(response == expectedResponse)
    }
    
    func testLoginExecute_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = DashboardRepositoryMock()
        
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setMatchResult(
            .failure(expectedError)
        )
        
        let sut = DashboardUseCases(dashboard: mockRepository)
        do {
            _ = try await sut.userRelatedMatches()
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
}
