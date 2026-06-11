//
//  MatchUseCasesProvider.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

/// A provider protocol for accessing match-related and notification-related use cases.
public protocol MatchDetailUseCasesProvider: Sendable {
    
    /// Provides access to match-specific use case operations.
    var matches: MatchUseCaseProtocol { get }
    /// Provides access to notification-specific use case operations.
    @MainActor var notifications: NotificationProtocol { get }
    /// Provides access to location-specific use case operations.
    @MainActor var location: LocationProtocol { get }
    
}
