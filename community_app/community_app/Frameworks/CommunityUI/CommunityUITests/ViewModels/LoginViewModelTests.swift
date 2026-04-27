//
//  LoginViewModelTests.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/27.
//

import XCTest
import Combine
@testable import CommunityUI
@testable import CommunityCore

final class LoginViewModelTests: XCTestCase {
    private var sut: LoginViewModel!
    private var mockProvider: AuthUseCasesProviderMock!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockProvider = AuthUseCasesProviderMock()
        sut = LoginViewModel(authUseCases: mockProvider)
    }
    
    @MainActor
    override func tearDown() {
        sut = nil
        mockProvider = nil
        super.tearDown()
    }
    
    @MainActor
    func testLoginAttempt_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse = LoginResponse(access_token: "12345_67890", token_type: "Bearer")
        mockProvider.mockVerifyLogin.result = .success(expectedResponse)
        sut.username = "test_user"
        sut.password = "password123"
        
        // Act
        sut.loginAttempt()
        
        // Wait for the Task to complete
        // We use a small delay or Task.yield since loginAttempt creates a detached Task
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .success(let response) = sut.state {
            XCTAssertTrue(response == expectedResponse)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }
    
    @MainActor
    func testLoginAttempt_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockVerifyLogin.result = .failure(error)
        
        // Act
        sut.loginAttempt()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state")
        }
    }
}
