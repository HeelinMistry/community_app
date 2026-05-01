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

@MainActor
final class LoginViewModelTests: XCTestCase {
    private var sut: LoginViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: AuthUseCasesProviderMock!
    
    override func setUp() {
        super.setUp()
        mockProvider = .init()
        mockRouter = .init()
        sut = .init(authUseCases: mockProvider, router: mockRouter)
    }
    
    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockProvider = nil
        super.tearDown()
    }
    
    func testLogin_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse = LoginResponse(access_token: "12345_67890", token_type: "Bearer", display_name: "Test")
        mockProvider.mockAuthUseCases.loginResult = .success(expectedResponse)
        sut.username = "test_user"
        sut.password = "password123"
        
        // Act
        sut.login()
        
        // Wait for the Task to complete
        // We use a small delay or Task.yield since loginAttempt creates a detached Task
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .success(let response) = sut.state {
            XCTAssertTrue(response == expectedResponse)
            XCTAssertTrue(mockRouter.isAuthenticated)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }
    }
    
    func testLogin_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockAuthUseCases.loginResult = .failure(error)
        
        // Act
        sut.login()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state")
        }
    }
    
    func test_whenShowRegistrationIsCalled_routerNavigatesToRegistration() {
        // Act
        sut.showRegistration()
        
        // Assert
        XCTAssertEqual(mockRouter.sheet, .registration)
    }
}
