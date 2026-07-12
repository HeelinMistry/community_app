//
//  SupplierUseCasesMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/11.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class SupplierUseCasesMock: SupplierUseCasesProtocol, @unchecked Sendable {
    
    var supplierResult: Result<Suppliers, Error>?
    func userNearbySuppliers(_ suppliersRequest: SupplierRequest) async throws -> Suppliers {
        if let result = supplierResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in SupplierUseCasesProtocol")
    }
    
    var createSupplierResult: Result<CreateSupplierResponse, Error>?
    func userCreateSupplier(_ supplierRequest: CreateSupplierRequest) async throws -> CreateSupplierResponse {
        if let result = createSupplierResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in SupplierUseCasesProtocol")
    }
    
}
