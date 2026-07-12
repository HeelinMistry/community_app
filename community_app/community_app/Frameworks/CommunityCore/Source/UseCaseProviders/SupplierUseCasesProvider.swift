//
//  SupplierUseCasesProvider.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/12.
//

public protocol SupplierUseCasesProvider: Sendable {
    
    /// Provides access to supplier-specific use case operations.
    @MainActor var suppliers: SupplierUseCasesProtocol { get }
    /// Provides access to location-specific use case operations.
    @MainActor var location: LocationProtocol { get }
    
}
