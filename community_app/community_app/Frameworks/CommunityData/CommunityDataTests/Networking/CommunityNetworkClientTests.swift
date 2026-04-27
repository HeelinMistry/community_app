//
//  CommunityNetworkClientTests.swift
//  community_appTests
//
//  Created by Heelin Mistry on 2026/04/27.
//

import XCTest
@testable import CommunityData
@testable import CommunityCore

final class CommunityNetworkClientTests: XCTestCase {
    var sut: CommunityNetworkClient!
    var session: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        session = URLSession(configuration: configuration)
        sut = CommunityNetworkClient(session: session)
    }

    override func tearDown() {
        URLProtocolMock.requestHandler = nil
        super.tearDown()
    }

    /// Tests that a non-200 HTTP status code throws a serverError with the correct code.
    func testFetch_WhenHttpStatusCodeIs404_ThrowsServerError() async {
        // Arrange
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        
        // Act & Assert
        do {
            let _: LoginResponse = try await sut.fetch(from: CommunityEndpoint.login(loginRequest: .init(username: "u", password: "p")))
            XCTFail("Expected .serverError(404), but no error was thrown.")
        } catch let error as NetworkError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 404)
            } else {
                XCTFail("Expected .serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// Tests that malformed JSON throws a decodingFailed error.
    func testFetch_WhenJsonIsMalformed_ThrowsDecodingFailed() async {
        // Arrange
        let invalidData = Data("invalid_json".utf8)
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, invalidData)
        }

        // Act & Assert
        do {
            let _: LoginResponse = try await sut.fetch(from: CommunityEndpoint.login(loginRequest: .init(username: "u", password: "p")))
            XCTFail("Expected .decodingFailed, but no error was thrown.")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
