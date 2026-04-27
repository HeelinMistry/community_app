//
//  VerifyLoginUseCaseTest.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

import XCTest
@testable import CommunityCore

final class VerifyUserLoginUseCaseTests: XCTestCase {
    
    private var sut: VerifyUserLoginUseCase! // System Under Test
    private var mockAuthRepository: AuthRepositoryMock!

    override func tearDown() {
        sut = nil
        mockAuthRepository = nil
        super.tearDown()
    }

    func testExecute_WhenLoginIsSuccessful_ReturnsSuccessResponse() async throws {
        mockAuthRepository = AuthRepositoryMock()
        
        let expected_response = LoginResponse(access_token: "12345_67890", token_type: "Bearer")
        await mockAuthRepository.setResult(
            .success(expected_response)
        )
        
        let sut = VerifyUserLoginUseCase(auth: mockAuthRepository)
        let response = try await sut.execute(LoginRequest(username: "user", password: "pw"))
        
        XCTAssertTrue(response == expected_response)
    }

    func testExecute_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockAuthRepository = AuthRepositoryMock()
        
        let request = LoginRequest(username: "testUser", password: "password123")
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockAuthRepository.setResult(
            .failure(expectedError)
        )
        
        let sut = VerifyUserLoginUseCase(auth: mockAuthRepository)
        do {
            _ = try await sut.execute(request)
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
}
