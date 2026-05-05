//
//  RegistrationViewModelTests.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/29.
//

import XCTest
import Combine
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class RegistrationViewModelTests: XCTestCase {
    private var sut: RegistrationViewModel!
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
    
    func testRegister_WhenSuccessful_SetsSuccessState() async {
        // Arrange
        let expectedResponse = RegisterResponse(success: true, detail: "Registered successfully")
        mockProvider.mockAuthUseCases.registerResult = .success(expectedResponse)
        
        // Act
        sut.register()
        
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
    
    func testRegister_WhenFails_SetsErrorState() async {
        // Arrange
        let errorMessage = "Invalid Credentials"
        let error = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        mockProvider.mockAuthUseCases.registerResult = .failure(error)
        
        // Act
        sut.register()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        if case .error(let message) = sut.state {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected .error state")
        }
    }
    
    func testRegister_InputValidation() async {
        var result = sut.isFormValid()
        XCTAssertFalse(result)
        XCTAssertFalse(sut.validationErrors.isEmpty)
        
        sut.username = "test"
        sut.displayName = "test"
        sut.email = "test@test.com"
        sut.cellNumber = "0987654567"
        sut.password = "longenough"
        result = sut.isFormValid()
        XCTAssertFalse(result)
        XCTAssertFalse(sut.validationErrors.isEmpty)
        
        sut.confirmPassword = "longenough"
        result = sut.isFormValid()
        XCTAssertTrue(result)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }
}
