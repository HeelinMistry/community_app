//
//  VerifyLoginUseCaseTest.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

import XCTest
@testable import CommunityCore

final class AuthUseCasesTests: XCTestCase {
    
    private var sut: AuthUseCases!
    private var mockAuthRepository: AuthRepositoryMock!

    override func tearDown() {
        sut = nil
        mockAuthRepository = nil
        super.tearDown()
    }

    func testLoginExecute_WhenLoginIsSuccessful_ReturnsSuccessResponse() async throws {
        mockAuthRepository = AuthRepositoryMock()
        
        let expected_response = LoginResponse(access_token: "12345_67890", token_type: "Bearer", display_name: "Test")
        await mockAuthRepository.setLoginResult(
            .success(expected_response)
        )
        
        let sut = AuthUseCases(auth: mockAuthRepository)
        let response = try await sut.execute(LoginRequest(username: "user", password: "pw"))
        
        XCTAssertTrue(response == expected_response)
    }

    func testLoginExecute_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockAuthRepository = AuthRepositoryMock()
        
        let request = LoginRequest(username: "testUser", password: "password123")
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockAuthRepository.setLoginResult(
            .failure(expectedError)
        )
        
        let sut = AuthUseCases(auth: mockAuthRepository)
        do {
            _ = try await sut.execute(request)
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
    
    func testRegisterExecute_WhenLoginIsSuccessful_ReturnsSuccessResponse() async throws {
        mockAuthRepository = AuthRepositoryMock()
        
        let expected_response = RegisterResponse(success: true, detail: "Successful register")
        await mockAuthRepository.setRegisterResult(
            .success(expected_response)
        )
        
        let sut = AuthUseCases(auth: mockAuthRepository)
        let response = try await sut.execute(
            RegisterRequest(
                username: "test_user",
                displayName: "DisplayName",
                email: "test@test.com",
                cellNumber: "0743575272",
                password: "hidden"
            )
        )
        
        XCTAssertTrue(response == expected_response)
    }

    func testRegisterExecute_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockAuthRepository = AuthRepositoryMock()
        
        let request = RegisterRequest(
            username: "test_user",
            displayName: "DisplayName",
            email: "test@test.com",
            cellNumber: "0743575272",
            password: "hidden"
        )
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockAuthRepository.setRegisterResult(
            .failure(expectedError)
        )
        
        let sut = AuthUseCases(auth: mockAuthRepository)
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
