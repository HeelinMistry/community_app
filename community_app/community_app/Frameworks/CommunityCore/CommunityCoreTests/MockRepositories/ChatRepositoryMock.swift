//
//  ChatRepositoryMock.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import CommunityCore

public actor ChatRepositoryMock: ChatRepositoryProtocol {
    private var continuation: AsyncStream<ChatMessage>.Continuation?
    public nonisolated let incomingMessages: AsyncStream<ChatMessage>

    private var chatsResult: Result<Chats, Error>?
    private var historyResult: Result<ChatHistory, Error>?
    private var connectResult: Result<Void, Error>? = .success(())
    private var sendResult: Result<Void, Error>? = .success(())

    private(set) var lastHistoryRequest: ChatDetailRequest?
    private(set) var lastConnectRequest: ChatDetailRequest?
    private(set) var connectCallCount = 0
    private(set) var sendCallCount = 0
    private(set) var sentMessages: [String] = []

    public init() {
        var capturedContinuation: AsyncStream<ChatMessage>.Continuation?
        self.incomingMessages = AsyncStream { cont in
            capturedContinuation = cont
        }
        self.continuation = capturedContinuation
    }

    func setChatsResult(_ result: Result<Chats, Error>) {
        self.chatsResult = result
    }

    func setHistoryResult(_ result: Result<ChatHistory, Error>) {
        self.historyResult = result
    }

    func setConnectResult(_ result: Result<Void, Error>) {
        self.connectResult = result
    }

    func setSendResult(_ result: Result<Void, Error>) {
        self.sendResult = result
    }

    func yieldIncomingMessage(_ message: ChatMessage) {
        continuation?.yield(message)
    }

    func finishIncomingMessages() {
        continuation?.finish()
    }

    public func getChats() async throws -> Chats {
        guard let result = chatsResult else {
            fatalError("Result not set in ChatRepositoryMock")
        }
        switch result {
        case .success(let response): return response
        case .failure(let error): throw error
        }
    }

    public func getHistory(request: ChatDetailRequest) async throws -> ChatHistory {
        lastHistoryRequest = request
        guard let result = historyResult else {
            fatalError("Result not set in ChatRepositoryMock")
        }
        switch result {
        case .success(let response): return response
        case .failure(let error): throw error
        }
    }

    public func connectWebSocket(request: ChatDetailRequest) async throws {
        connectCallCount += 1
        lastConnectRequest = request
        if let result = connectResult {
            switch result {
            case .success: return
            case .failure(let error): throw error
            }
        }
    }

    public func sendMessage(content: String) async throws {
        sendCallCount += 1
        sentMessages.append(content)
        if let result = sendResult {
            switch result {
            case .success: return
            case .failure(let error): throw error
            }
        }
    }
}
