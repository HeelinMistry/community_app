//
//  ProductUseCasesMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/12.
//

import UIKit
import Foundation
import CommunityCore
@testable import CommunityUI

final class ProductUseCasesMock: ProductUseCasesProtocol, @unchecked Sendable {
    
    var classifyResult: Result<(title: String, tags: [String]), Error>?
    func classify(_ images: [UIImage]) async throws -> (title: String, tags: [String]) {
        if let result = classifyResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in ProductUseCasesProtocol")
    
    }
    
    var createProductResult: Result<AdvertiseProductResponse, Error>?
    func advertise(_ item: AdvertiseProductRequest) async throws -> AdvertiseProductResponse {
        if let result = createProductResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in ProductUseCasesProtocol")
    }
    
    var productResult: Result<Products, Error>?
    func userNearbyProducts(_ productRequest: LocationRequest) async throws -> Products {
        if let result = productResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in ProductUseCasesProtocol")
    }
    
    var productImagesResult: Result<ProductImagesResponse, Error>?
    func link(productId: String, images: [UIImage]) async throws -> ProductImagesResponse {
        if let result = productImagesResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in ProductUseCasesProtocol")
    }
    
    var productDetailResult: Result<ProductDetailResponse, Error>?
    func selectedProduct(_ productRequest: DetailRequest) async throws -> ProductDetailResponse {
        if let result = productDetailResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in ProductUseCasesProtocol")
    }
    
    var imageURL: Result<URL, Error>?
    func imageDownloadable(url: String) async throws -> URL {
        if let result = imageURL {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in ProductUseCasesProtocol")
    }
    
}
