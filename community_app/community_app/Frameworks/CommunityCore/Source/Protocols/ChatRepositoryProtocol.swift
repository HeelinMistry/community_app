//
//  ChatRepositoryProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/11/07.
//

public protocol ChatRepositoryProtocol: Sendable {

    func getChats() async throws -> Chats
}

public protocol ChatUseCaseProtocol: Sendable {
    func userRelatedChats() async throws -> Chats

}
