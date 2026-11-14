//
//  ChatRepository.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore

public final class ChatRepository: ChatRepositoryProtocol {
    
    private let networkClient: CommunityNetworkClient
    private var webSocketTask: URLSessionWebSocketTask?
    
    private var messageContinuation: AsyncStream<ChatMessage>.Continuation?
    
    public private(set) lazy var incomingMessages: AsyncStream<ChatMessage> = {
        AsyncStream { continuation in
            self.messageContinuation = continuation
        }
    }()
    
    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
    }
    
    public func getChats() async throws -> Chats {
        do {
            let dto: Chats = try await networkClient.fetch(from: CommunityEndpoint.chats)
            return dto
        } catch {
            throw error
        }
    }
    
    public func connectWebSocket(request: ChatDetailRequest) async throws {
        // Clean up any existing task
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        
        // Obtain the fully authenticated websocket task from your network client actor
        webSocketTask = try await networkClient.connectWebSocket(for: CommunityEndpoint.chatDetail(request))
        
        // Start listening loop
        listenForMessages()
    }
    
    public func disconnectWebSocket() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    public func sendMessage(content: String) async throws {
        let payload: [String: Any] = ["content": content]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        
        try await webSocketTask?.send(.string(jsonString))
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            Task {
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        if let data = text.data(using: .utf8),
                           let chatMsg = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                            // Yield message to the stream
                            self.messageContinuation?.yield(chatMsg)
                        }
                    case .data(let data):
                        if let chatMsg = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                            self.messageContinuation?.yield(chatMsg)
                        }
                    @unknown default:
                        break
                    }
                    // Continue listening loop
                    self.listenForMessages()
                case .failure(let error):
                    print("WebSocket receive error: \((error as NSError).localizedDescription)")
                }
            }
        }
    }
}
