//
//  DashboardUseCase.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

public final class ChatUseCases: ChatUseCaseProtocol {
    
    private let chat: any ChatRepositoryProtocol

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
}
