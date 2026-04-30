//
//  AuthRepositoryTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/27.
//

import XCTest
@testable import CommunityData
@testable import CommunityCore

final class AuthRepositoryTests: XCTestCase {
    var sut: AuthRepository!
    var networkClient: CommunityNetworkClient!
    var session: URLSession!

    override func setUp() {
        super.setUp()
        // Configure a session to use our MockURLProtocol
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        session = URLSession(configuration: configuration)
        networkClient = CommunityNetworkClient(
            session: session,
            networkConfig: .init(
                baseURL: URL(string: "http://test.com/")!,
                shouldLogSensitiveData: true)
        )
        sut = AuthRepository(networkClient: networkClient)
    }

    override func tearDown() {
        sut = nil
        networkClient = nil
        URLProtocolMock.requestHandler = nil
        super.tearDown()
    }

    func testVerifyUserLogin_WhenServerReturnsSuccess_ReturnsLoginResponse() async throws {
        let expectedResponse = LoginResponse(access_token: "12345_67890", token_type: "Bearer")
        let responseData = try JSONEncoder().encode(expectedResponse)
        let request = LoginRequest(username: "test", password: "password")
        
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        // Act
        let result = try await sut.loginUser(loginRequest: request)

        // Assert
        XCTAssertTrue(result == expectedResponse)
    }

    func testVerifyUserLogin_WhenServerReturns401_ThrowsServerError() async {
        // Arrange
        let request = LoginRequest(username: "wrong", password: "user")
        
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // Act & Assert
        do {
            _ = try await sut.loginUser(loginRequest: request)
            XCTFail("Should throw serverError(401)")
        } catch let error as NetworkError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 401)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    
    func testRegisterUser_WhenServerReturnsSuccess_ReturnsLoginResponse() async throws {
        let expectedResponse = RegisterResponse(success: true, detail: "User created")
        let responseData = try JSONEncoder().encode(expectedResponse)
        let request = RegisterRequest(username: "", displayName: "", email: "", cellNumber: "", password: "")
        
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        // Act
        let result = try await sut.registerUser(registerRequest: request)

        // Assert
        XCTAssertTrue(result == expectedResponse)
    }

    func testRegisterUser_WhenServerReturns401_ThrowsServerError() async {
        // Arrange
        let request = RegisterRequest(username: "", displayName: "", email: "", cellNumber: "", password: "")

        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // Act & Assert
        do {
            _ = try await sut.registerUser(registerRequest: request)
            XCTFail("Should throw serverError(401)")
        } catch let error as NetworkError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 401)
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
