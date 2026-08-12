//
//  SupplierRepositoryProtocol.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/10.
//

public protocol SupplierRepositoryProtocol: Sendable {

    func nearbySuppliers(_ suppliersRequest: LocationRequest) async throws -> Suppliers
    func createSupplier(_ supplierRequest: CreateSupplierRequest) async throws -> CreateSupplierResponse
    func supplierDetails(_ supplierRequest: SupplierDetailRequest) async throws -> SupplierDetailResponse
}

public protocol SupplierUseCasesProtocol: Sendable {
    func userNearbySuppliers(_ suppliersRequest: LocationRequest) async throws -> Suppliers
    func userCreateSupplier(_ supplierRequest: CreateSupplierRequest) async throws -> CreateSupplierResponse
    func selectedSupplierDetails(_ supplierRequest: SupplierDetailRequest) async throws -> SupplierDetailResponse

}
