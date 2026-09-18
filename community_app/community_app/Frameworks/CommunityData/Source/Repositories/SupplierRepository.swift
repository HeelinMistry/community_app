//
//  SupplierRepository.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/10.
//

import Foundation
import CommunityCore

public final class SupplierRepository: SupplierRepositoryProtocol {
    
    private let networkClient: CommunityNetworkClient
    
    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
    }
    
    public func nearbySuppliers(_ suppliersRequest: LocationRequest) async throws -> Suppliers {
        do {
            let dto: Suppliers = try await networkClient.fetch(from: CommunityEndpoint.suppliers(suppliersRequest))
            return dto
        } catch {
            throw error
        }
    }
    
    public func createSupplier(_ supplierRequest: CreateSupplierRequest) async throws -> CreateSupplierResponse {
        do {
            let dto: CreateSupplierResponse = try await networkClient.fetch(from: CommunityEndpoint.createSupplier(supplierRequest))
            return dto
        } catch {
            throw error
        }
    }
    
    public func supplierDetails(_ supplierRequest: DetailRequest) async throws -> SupplierDetailResponse {
        do {
            let dto: SupplierDetailResponse = try await networkClient.fetch(from: CommunityEndpoint.supplier(supplierRequest))
            return dto
        } catch {
            throw error
        }
    }
}
