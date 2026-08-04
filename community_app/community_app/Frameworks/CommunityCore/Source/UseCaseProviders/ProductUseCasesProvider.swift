//
//  ProductUseCasesProvider.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/07/29.
//

public protocol ProductUseCasesProvider: Sendable {
    
    /// Provides access to supplier-specific use case operations.
    @MainActor var products: ProductUseCasesProtocol { get }
    /// Provides access to location-specific use case operations.
    @MainActor var location: LocationProtocol { get }
    
}
