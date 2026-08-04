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
}
