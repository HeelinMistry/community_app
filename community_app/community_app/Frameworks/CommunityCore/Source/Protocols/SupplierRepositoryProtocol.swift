//
//  SupplierRepositoryProtocol.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/10.
//

public protocol SupplierRepositoryProtocol: Sendable {

    func nearbySuppliers(_ suppliersRequest: SupplierRequest) async throws -> Suppliers
}

public protocol SupplierUseCasesProtocol: Sendable {
    func nearbySuppliers(_ suppliersRequest: SupplierRequest) async throws -> Suppliers

}
