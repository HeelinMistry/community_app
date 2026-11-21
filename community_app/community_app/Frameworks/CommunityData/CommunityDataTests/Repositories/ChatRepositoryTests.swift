//
//  ChatRepositoryTests.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/11/21.
//

import XCTest
@testable import CommunityData
@testable import CommunityCore

final class ChatRepositoryTests: XCTestCase {
    var sut: ChatRepository!
    var networkClient: CommunityNetworkClient!
    var session: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolMock.self]
        session = URLSession(configuration: configuration)
        networkClient = CommunityNetworkClient(
            session: session,
            networkConfig: .init(
                baseURL: URL(string: "http://test.com/")!,
                shouldLogSensitiveData: true
            )
        )
        sut = ChatRepository(networkClient: networkClient)
    }

    override func tearDown() {
        sut = nil
        networkClient = nil
        session = nil
        URLProtocolMock.requestHandler = nil
        super.tearDown()
    }

    // MARK: - getChats

    func testGetChats_WhenServerReturnsSuccess_ReturnsResponse() async throws {
        let expectedResponse: Chats = .init()
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
        let result = try await sut.getChats()

        // Assert
        XCTAssertTrue(result == expectedResponse)
    }

    func testGetChats_WhenServerReturns401_ThrowsServerError() async {
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
            _ = try await sut.getChats()
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

    // MARK: - getHistory

    func testGetHistory_WhenServerReturnsSuccess_ReturnsResponse() async throws {
        let expectedResponse: ChatHistory = .init()
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
        let result = try await sut.getHistory(request: .init("rm24_2344"))

        // Assert
        XCTAssertTrue(result == expectedResponse)
    }

    func testGetHistory_WhenServerReturns401_ThrowsServerError() async {
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
            _ = try await sut.getHistory(request: .init("rm24_2344"))
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

    // MARK: - WebSocket Lifecycle & Messaging

    func testConnectWebSocket_WhenEndpointIsValid_Succeeds() async throws {
        // Act & Assert (no error thrown)
        try await sut.connectWebSocket(request: .init("rm24_2344"))
        await sut.disconnectWebSocket()
    }

    func testSendMessage_BeforeConnectingWebSocket_DoesNotThrow() async throws {
        // webSocketTask is nil prior to connectWebSocket; optional send is a no-op
        try await sut.sendMessage(content: "Hello, community!")
    }

    func testDisconnectWebSocket_ClearsActiveTaskSafely() async throws {
        try await sut.connectWebSocket(request: .init("rm24_2344"))
        await sut.disconnectWebSocket()

        // Calling disconnect again and sending a message should remain safe
        await sut.disconnectWebSocket()
        try await sut.sendMessage(content: "After disconnect")
    }
}
