//
//  ChatRepository.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore

public actor ChatRepository: ChatRepositoryProtocol {
    
    private let networkClient: CommunityNetworkClient
    private var webSocketTask: URLSessionWebSocketTask?
    private var messageContinuation: AsyncStream<ChatMessage>.Continuation?
    
    public nonisolated let incomingMessages: AsyncStream<ChatMessage>
    
    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
        
        var capturedContinuation: AsyncStream<ChatMessage>.Continuation?
        self.incomingMessages = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        self.messageContinuation = capturedContinuation
    }
    
    public func getChats() async throws -> Chats {
        try await networkClient.fetch(from: CommunityEndpoint.chats)
    }
    
    public func getHistory(request: ChatDetailRequest) async throws -> ChatHistory {
        try await networkClient.fetch(from: CommunityEndpoint.chatHistory(request))
    }
    
    public func connectWebSocket(request: ChatDetailRequest) async throws {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = try await networkClient.connectWebSocket(for: CommunityEndpoint.chatDetail(request))
        listenForMessages()
    }
    
    public func disconnectWebSocket() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    public func sendMessage(content: String) async throws {
        let payload: [String: String] = ["content": content]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        
        try await webSocketTask?.send(.string(jsonString))
    }
    
    private func listenForMessages() {
        guard let task = webSocketTask else { return }
        
        task.receive { [weak self] result in
            Task { [weak self] in
                guard let self else { return }
                await self.handleReceiveResult(result)
            }
        }
    }
    
    private func handleReceiveResult(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
        switch result {
        case .success(let message):
            switch message {
            case .string(let text):
                if let data = text.data(using: .utf8),
                   let chatMsg = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                    messageContinuation?.yield(chatMsg)
                }
            case .data(let data):
                if let chatMsg = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                    messageContinuation?.yield(chatMsg)
                }
            @unknown default:
                break
            }
            listenForMessages()
            
        case .failure(let error):
            print("WebSocket receive error: \(error.localizedDescription)")
        }
    }
}
