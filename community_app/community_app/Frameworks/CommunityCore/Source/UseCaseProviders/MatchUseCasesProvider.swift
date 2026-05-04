//
//  MatchUseCasesProvider.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

/// A provider protocol for various dashboard-related use cases.
@MainActor
public protocol MatchUseCasesProvider {
    
    /// The use case for verifying a user's login credentials.
    var matches: MatchUseCaseProtocol { get }
}
