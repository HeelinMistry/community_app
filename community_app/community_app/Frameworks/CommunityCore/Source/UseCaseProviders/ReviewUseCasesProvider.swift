//
//  ReviewUseCasesProvider.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/10/13.
//

public protocol ReviewUseCasesProvider: Sendable {
    
    /// Provides access to review-specific use case operations.
    @MainActor var reviews: ReviewUseCasesProtocol { get }
    /// Provides access to location-specific use case operations.
    @MainActor var location: LocationProtocol { get }
    
}
