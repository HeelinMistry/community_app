//
//  ProductUseCases.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/07/29.
//

import UIKit

public final class ProductUseCases: ProductUseCasesProtocol {
    
    private let product: any ProductRepositoryProtocol
    
    public init(product: any ProductRepositoryProtocol) {
        self.product = product
    }
    
    public func classify(_ images: [UIImage]) async throws -> (title: String, tags: [String]) {
        return try await product.classify(images)
    }
    
    public func advertise(_ item: AdvertiseProductRequest) async throws -> AdvertiseProductResponse {
        return try await product.create(item)
    }
    
    public func userNearbyProducts(_ productRequest: LocationRequest) async throws -> Products {
        do {
            let productResponse = try await product.nearbyProducts(productRequest)
            return productResponse
        } catch {
            throw error
        }
    }
    
    public func link(productId: String, images: [UIImage]) async throws -> ProductImagesResponse {
        do {
            let productResponse = try await product.upload(productId: productId, images: images)
            return productResponse
        } catch {
            throw error
        }
    }
    
    public func selectedProduct(_ productRequest: DetailRequest) async throws -> ProductDetailResponse {
        do {
            let productResponse = try await product.productDetails(productRequest)
            return productResponse
        } catch {
            throw error
        }
    }
    
}
