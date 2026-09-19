//
//  ProductRepositoryMock.swift
//  CommunityCoreTests
//
//  Created by Heelin Mistry on 2026/09/19.
//

import Foundation
import UIKit
import CommunityCore

// A mock repository to simulate network behavior
public actor ProductRepositoryMock: ProductRepositoryProtocol {

    var classifyResult: Result<(title: String, tags: [String]), Error>?
    var createResult: Result<AdvertiseProductResponse, Error>?
    var nearbyProductsResult: Result<Products, Error>?
    var productDetailsResult: Result<ProductDetailResponse, Error>?
    var uploadResult: Result<ProductImagesResponse, Error>?

    func setClassifyResult(_ result: Result<(title: String, tags: [String]), Error>) {
        classifyResult = result
    }

    func setCreateResult(_ result: Result<AdvertiseProductResponse, Error>) {
        createResult = result
    }

    func setNearbyProductsResult(_ result: Result<Products, Error>) {
        nearbyProductsResult = result
    }

    func setProductDetailsResult(_ result: Result<ProductDetailResponse, Error>) {
        productDetailsResult = result
    }

    func setUploadResult(_ result: Result<ProductImagesResponse, Error>) {
        uploadResult = result
    }

    public func classify(_ images: [UIImage]) async throws -> (title: String, tags: [String]) {
        try result(for: classifyResult)
    }

    public func create(_ product: AdvertiseProductRequest) async throws -> AdvertiseProductResponse {
        try result(for: createResult)
    }

    public func nearbyProducts(_ productRequest: LocationRequest) async throws -> Products {
        try result(for: nearbyProductsResult)
    }

    public func productDetails(_ productRequest: DetailRequest) async throws -> ProductDetailResponse {
        try result(for: productDetailsResult)
    }

    public func upload(productId: String, images: [UIImage]) async throws -> ProductImagesResponse {
        try result(for: uploadResult)
    }

    public func image(url: String) async throws -> URL {
        fatalError("image(url:) is not used by ProductUseCases")
    }

    private func result<Response>(for result: Result<Response, Error>?) throws -> Response {
        guard let result else {
            fatalError("Result not set in ProductRepositoryMock")
        }

        return try result.get()
    }
}
