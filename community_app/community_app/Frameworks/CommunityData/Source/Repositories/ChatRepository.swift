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
}
