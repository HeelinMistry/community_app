//
//  ChatDetailUseCasesProvider.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

/// A provider protocol for accessing match-related and notification-related use cases.
public protocol ChatDetailUseCasesProvider: Sendable {
    
    /// Provides access to match-specific use case operations.
    @MainActor var chats: ChatUseCaseProtocol { get }
    
}
