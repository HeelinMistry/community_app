//
//  DashboardRepositoryTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import XCTest
@testable import CommunityData
@testable import CommunityCore

final class MatchRepositoryTests: XCTestCase {
    var sut: MatchRepository!
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
        sut = MatchRepository(networkClient: networkClient)
    }

    override func tearDown() {
        sut = nil
        networkClient = nil
        URLProtocolMock.requestHandler = nil
        super.tearDown()
    }

    func testGetMatches_WhenServerReturnsSuccess_ReturnsResponse() async throws {
        let expectedResponse: Matches = [.init()]
        let responseData = try JSONEncoder().encode(expectedResponse)
        
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
        let result = try await sut.getMatches()

        // Assert
        XCTAssertTrue(result == expectedResponse)
    }

    func testVerifyUserLogin_WhenServerReturns401_ThrowsServerError() async {
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
            _ = try await sut.getMatches()
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
    
    func testCreateMatch_WhenServerReturnsSuccess_ReturnsResponse() async throws {
        let expectedResponse: CreateMatchResponse = .init(match_id: "test_id")
        let responseData = try JSONEncoder().encode(expectedResponse)
        
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
        let result = try await sut.createMatch(.init())

        // Assert
        XCTAssertTrue(result == expectedResponse)
    }
    
    func testCreateMatch_WhenServerReturns401_ThrowsServerError() async {
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
            _ = try await sut.createMatch(.init())
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
