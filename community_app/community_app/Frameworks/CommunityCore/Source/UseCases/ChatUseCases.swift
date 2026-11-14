//
//  DashboardUseCase.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

public final class ChatUseCases: ChatUseCaseProtocol {
    
    private let chat: any ChatRepositoryProtocol
    
    public var incomingMessages: AsyncStream<ChatMessage> {
        return chat.incomingMessages
    }
    
    public init(chat: any ChatRepositoryProtocol) {
        self.chat = chat
    }

    public func userRelatedChats() async throws -> Chats {
        do {
            let chatResponse = try await chat.getChats()
            return (chatResponse)
        } catch {
            throw error
        }
    }
    
    public func connect(request: ChatDetailRequest) async throws {
        do {
            return try await chat.connectWebSocket(request: request)
        } catch {
            throw error
        }
    }
    
    public func send(content: String) async throws {
        do {
            return try await chat.sendMessage(content: content)
        } catch {
            throw error
        }
    }
    
//    public func listenForMessages() {
//        chat.listenForMessages()
//    }
}
