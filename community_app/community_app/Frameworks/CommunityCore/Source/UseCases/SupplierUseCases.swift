//
//  SupplierUseCases.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/10.
//

public final class SupplierUseCases: SupplierUseCasesProtocol {
    
    private let supplier: any SupplierRepositoryProtocol
    
    public init(supplier: any SupplierRepositoryProtocol) {
        self.supplier = supplier
    }
    
    public func nearbySuppliers(_ suppliersRequest: SupplierRequest) async throws -> Suppliers {
        do {
            let supplierResponse = try await supplier.nearbySuppliers(suppliersRequest)
            return supplierResponse
        } catch {
            throw error
        }
    }
}
