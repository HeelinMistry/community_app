//
//  SupplierRepositoryMock.swift
//  CommunityCoreTests
//
//  Created by Heelin Mistry on 2026/09/19.
//

import Foundation
import CommunityCore

// A mock repository to simulate network behavior
public actor SupplierRepositoryMock: SupplierRepositoryProtocol {

    var nearbySuppliersResult: Result<Suppliers, Error>?

    func setNearbySuppliersResult(_ result: Result<Suppliers, Error>) {
        nearbySuppliersResult = result
    }

    public func nearbySuppliers(_ suppliersRequest: LocationRequest) async throws -> Suppliers {
        guard let result = nearbySuppliersResult else {
            fatalError("Result not set in RepositoryMock")
        }

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    var createSupplierResult: Result<CreateSupplierResponse, Error>?

    func setCreateSupplierResult(_ result: Result<CreateSupplierResponse, Error>) {
        createSupplierResult = result
    }

    public func createSupplier(_ supplierRequest: CreateSupplierRequest) async throws -> CreateSupplierResponse {
        guard let result = createSupplierResult else {
            fatalError("Result not set in RepositoryMock")
        }

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    var supplierDetailResult: Result<SupplierDetailResponse, Error>?

    func setSupplierDetailResult(_ result: Result<SupplierDetailResponse, Error>) {
        supplierDetailResult = result
    }

    public func supplierDetails(_ supplierRequest: DetailRequest) async throws -> SupplierDetailResponse {
        guard let result = supplierDetailResult else {
            fatalError("Result not set in RepositoryMock")
        }

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}
