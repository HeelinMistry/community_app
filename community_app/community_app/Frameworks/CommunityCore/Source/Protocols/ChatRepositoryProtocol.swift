//
//  ChatRepositoryProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/11/07.
//

public protocol ChatRepositoryProtocol: Sendable {

    func getChats() async throws -> Chats
    func getHistory(request: ChatDetailRequest) async throws -> ChatHistory
    func connectWebSocket(request: ChatDetailRequest) async throws
    func sendMessage(content: String) async throws 
    var incomingMessages: AsyncStream<ChatMessage> { get }
}

public protocol ChatUseCaseProtocol: Sendable {
    func userRelatedChats() async throws -> Chats
    func getHistory(request: ChatDetailRequest) async throws -> ChatHistory
    func connect(request: ChatDetailRequest) async throws
    func send(content: String) async throws 
    var incomingMessages: AsyncStream<ChatMessage> { get } 

}
