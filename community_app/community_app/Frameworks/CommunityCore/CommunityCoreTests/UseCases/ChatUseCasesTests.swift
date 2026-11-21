//
//  ChatUseCasesTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/11/21.
//

import XCTest
@testable import CommunityCore

final class ChatUseCasesTests: XCTestCase {

    private var sut: ChatUseCases!
    private var mockRepository: ChatRepositoryMock!

    override func setUp() {
        super.setUp()
        mockRepository = ChatRepositoryMock()
        sut = ChatUseCases(chat: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - userRelatedChats()

    func testUserRelatedChats_WhenSuccessful_ReturnsSuccessResponse() async throws {
        let expectedResponse: Chats = .init()
        await mockRepository.setChatsResult(.success(expectedResponse))

        let response = try await sut.userRelatedChats()

        XCTAssertTrue(response == expectedResponse)
    }

    func testUserRelatedChats_WhenRepositoryThrowsError_ThrowsSameError() async {
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setChatsResult(.failure(expectedError))

        do {
            _ = try await sut.userRelatedChats()
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }

    // MARK: - getHistory(request:)

    func testGetHistory_WhenSuccessful_ReturnsHistoryAndPassesRequest() async throws {
        let expectedHistory: ChatHistory = []
        let request = ChatDetailRequest("room_123")
        await mockRepository.setHistoryResult(.success(expectedHistory))

        let response = try await sut.getHistory(request: request)
        let recordedRequest = await mockRepository.lastHistoryRequest

        XCTAssertTrue(response == expectedHistory)
        XCTAssertEqual(recordedRequest?.room_id, "room_123")
    }

    func testGetHistory_WhenRepositoryThrowsError_ThrowsSameError() async {
        let expectedError = NSError(domain: "NetworkError", code: 500, userInfo: nil)
        await mockRepository.setHistoryResult(.failure(expectedError))

        do {
            _ = try await sut.getHistory(request: ChatDetailRequest("room_123"))
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 500)
        }
    }

    // MARK: - connect(request:)

    func testConnect_WhenSuccessful_ConnectsWebSocketAndPassesRequest() async throws {
        let request = ChatDetailRequest("room_123")
        await mockRepository.setConnectResult(.success(()))

        try await sut.connect(request: request)

        let connectCallCount = await mockRepository.connectCallCount
        let recordedRequest = await mockRepository.lastConnectRequest
        XCTAssertEqual(connectCallCount, 1)
        XCTAssertEqual(recordedRequest?.room_id, "room_123")
    }

    func testConnect_WhenRepositoryThrowsError_ThrowsSameError() async {
        let expectedError = NSError(domain: "SocketError", code: 503, userInfo: nil)
        await mockRepository.setConnectResult(.failure(expectedError))

        do {
            try await sut.connect(request: ChatDetailRequest("room_123"))
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "SocketError")
            XCTAssertEqual(nsError.code, 503)
        }
    }

    // MARK: - send(content:)

    func testSend_WhenSuccessful_SendsContent() async throws {
        await mockRepository.setSendResult(.success(()))

        try await sut.send(content: "Hello everyone")

        let sendCallCount = await mockRepository.sendCallCount
        let sentMessages = await mockRepository.sentMessages
        XCTAssertEqual(sendCallCount, 1)
        XCTAssertEqual(sentMessages, ["Hello everyone"])
    }

    func testSend_WhenRepositoryThrowsError_ThrowsSameError() async {
        let expectedError = NSError(domain: "SocketError", code: 400, userInfo: nil)
        await mockRepository.setSendResult(.failure(expectedError))

        do {
            try await sut.send(content: "Hello everyone")
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "SocketError")
            XCTAssertEqual(nsError.code, 400)
        }
    }

    // MARK: - incomingMessages

    func testIncomingMessages_ForwardsStreamFromRepository() async {
        let message = ChatMessage(messageId: "m_1", content: "Streamed message")
        await mockRepository.yieldIncomingMessage(message)
        await mockRepository.finishIncomingMessages()

        var received: [ChatMessage] = []
        for await item in sut.incomingMessages {
            received.append(item)
        }

        XCTAssertEqual(received, [message])
    }
}
