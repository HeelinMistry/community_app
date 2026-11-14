//
//  ChatUseCasesMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class ChatUseCasesMock: ChatUseCaseProtocol, @unchecked Sendable {
    
    // MARK: - Incoming Messages Stream
    public let incomingMessages: AsyncStream<ChatMessage>
    public let messageContinuation: AsyncStream<ChatMessage>.Continuation
    
    public init() {
        var continuation: AsyncStream<ChatMessage>.Continuation!
        self.incomingMessages = AsyncStream { cont in
            continuation = cont
        }
        self.messageContinuation = continuation
    }
    
    // MARK: - Chats Result
    var chatResult: Result<Chats, Error>?
    func userRelatedChats() async throws -> Chats {
        if let result = chatResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in ChatUseCaseProtocol")
    }
    
    // MARK: - Connect
    var connectResult: Result<Void, Error>? = .success(())
    var connectCallCount = 0
    var lastConnectRequest: ChatDetailRequest?
    
    func connect(request: ChatDetailRequest) async throws {
        connectCallCount += 1
        lastConnectRequest = request
        
        if let result = connectResult {
            switch result {
            case .success: return
            case .failure(let error): throw error
            }
        }
    }
    
    // MARK: - Send
    var sendResult: Result<Void, Error>? = .success(())
    var sendCallCount = 0
    var sentContents: [String] = []
    
    func send(content: String) async throws {
        sendCallCount += 1
        sentContents.append(content)
        
        if let result = sendResult {
            switch result {
            case .success: return
            case .failure(let error): throw error
            }
        }
    }
}
