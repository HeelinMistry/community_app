//
//  DashboardUseCasesProvider.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/10.
//

public protocol DashboardUseCasesProvider: Sendable {
    
    @MainActor var matches: MatchUseCaseProtocol { get }
    
    @MainActor var suppliers: SupplierUseCasesProtocol { get }
    
    /// Provides access to location-specific use case operations.
    @MainActor var location: LocationProtocol { get }
}
