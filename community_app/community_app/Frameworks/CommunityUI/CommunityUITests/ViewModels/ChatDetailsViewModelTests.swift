//
//  ChatDetailsViewModelTests.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/11/21.
//
//
//  ChatDetailsViewModelTests.swift
//  CommunityUI
//

import XCTest
import Combine
@testable import CommunityUI
@testable import CommunityCore

@MainActor
final class ChatDetailsViewModelTests: XCTestCase {
    private var sut: ChatDetailsViewModel!
    private var mockRouter: NavigationRouter!
    private var mockProvider: ChatDetailUseCasesProviderMock!
    private var cancellables: Set<AnyCancellable>!

    private let testRoomID = "test_room_id_123"

    override func setUp() {
        super.setUp()
        mockProvider = ChatDetailUseCasesProviderMock()
        mockRouter = NavigationRouter()
        cancellables = []
        sut = ChatDetailsViewModel(
            useCases: mockProvider,
            router: mockRouter,
            room_id: testRoomID
        )
    }

    override func tearDown() {
        sut.disconnect()
        mockProvider.chatsMock.messageContinuation.finish()
        sut = nil
        mockRouter = nil
        mockProvider = nil
        cancellables = nil
        super.tearDown()
    }

    func testInitialState_IsIdleWithEmptyMessagesAndInput() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.messages.isEmpty)
        XCTAssertEqual(sut.inputText, "")
        XCTAssertEqual(mockProvider.chatsMock.connectCallCount, 0)
        XCTAssertEqual(mockProvider.chatsMock.sendCallCount, 0)
    }

    func testGetHistory_WhenSuccessful_LoadsHistoryConnectsAndReceivesIncomingMessages() async {
        // Arrange
        let initialMessages: ChatHistory = [
            ChatMessage(messageId: "msg-1", content: "Hello")
        ]
        let streamMessage = ChatMessage(messageId: "msg-2", content: "Hi there!")

        mockProvider.chatsMock.chatHistoryResult = .success(initialMessages)
        mockProvider.chatsMock.connectResult = .success(())

        // Act
        sut.getHistory()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert history + connection
        XCTAssertEqual(mockProvider.chatsMock.connectCallCount, 1)
        XCTAssertEqual(mockProvider.chatsMock.lastConnectRequest?.room_id, testRoomID)
        XCTAssertEqual(sut.messages, initialMessages)
        if case .success(let stateMessages) = sut.state {
            XCTAssertEqual(stateMessages, initialMessages)
        } else {
            XCTFail("Expected .success state, got \(sut.state)")
        }

        // Act - Yield an incoming message via the mock stream continuation
        mockProvider.chatsMock.messageContinuation.yield(streamMessage)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert incoming message appended on @MainActor
        XCTAssertEqual(sut.messages, initialMessages + [streamMessage])
    }

    func testGetHistory_WhenHistoryFails_SetsErrorStateAndDoesNotConnect() async {
        // Arrange
        let errorMessage = "Failed to load chat history"
        let error = NSError(
            domain: "ChatHistoryError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        mockProvider.chatsMock.chatHistoryResult = .failure(error)

        // Act
        sut.getHistory()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        if case .error(let receivedMessage) = sut.state {
            XCTAssertEqual(receivedMessage, errorMessage)
        } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
        XCTAssertEqual(mockProvider.chatsMock.connectCallCount, 0)
        XCTAssertNil(mockProvider.chatsMock.lastConnectRequest)
        XCTAssertTrue(sut.messages.isEmpty)
    }

    func testGetHistory_WhenConnectFails_SetsErrorState() async {
        // Arrange
        let initialMessages: ChatHistory = [ChatMessage(messageId: "msg-1", content: "Earlier message")]
        let errorMessage = "Unable to connect to room"
        let error = NSError(
            domain: "ChatConnectError",
            code: 503,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )

        mockProvider.chatsMock.chatHistoryResult = .success(initialMessages)
        mockProvider.chatsMock.connectResult = .failure(error)

        // Act
        sut.getHistory()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(mockProvider.chatsMock.connectCallCount, 1)
        XCTAssertEqual(sut.messages, initialMessages)
        if case .error(let receivedMessage) = sut.state {
            XCTAssertEqual(receivedMessage, errorMessage)
        } else {
            XCTFail("Expected .error state when connect fails, got \(sut.state)")
        }
    }

    func testGetHistory_WhenAlreadyLoading_IgnoresDuplicateCall() async {
        // Arrange
        mockProvider.chatsMock.chatHistoryResult = .success([])

        // Act - First call sets sut.state = .loading synchronously before awaiting
        sut.getHistory()
        sut.getHistory()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(mockProvider.chatsMock.connectCallCount, 1)
    }

    func testSendMessage_TrimsInputClearsTextAndCallsUseCase() async {
        // Arrange
        sut.inputText = "   Hello team!   \n"

        // Act
        sut.sendMessage()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(sut.inputText, "")
        XCTAssertEqual(mockProvider.chatsMock.sendCallCount, 1)
        XCTAssertEqual(mockProvider.chatsMock.sentContents, ["Hello team!"])
    }

    func testSendMessage_WhenInputIsWhitespaceOnly_DoesNotSend() async {
        // Arrange
        sut.inputText = "   \n  \t "

        // Act
        sut.sendMessage()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Assert
        XCTAssertEqual(mockProvider.chatsMock.sendCallCount, 0)
        XCTAssertTrue(mockProvider.chatsMock.sentContents.isEmpty)
    }

    func testDisconnect_CancelsListeningTaskSoLaterMessagesAreNotAppended() async {
        // Arrange
        mockProvider.chatsMock.chatHistoryResult = .success([])
        mockProvider.chatsMock.connectResult = .success(())

        sut.getHistory()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Act
        sut.disconnect()
        mockProvider.chatsMock.messageContinuation.yield(ChatMessage(messageId: "msg-after-disconnect", content: "Ignored"))
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertTrue(sut.messages.isEmpty)
    }
}
