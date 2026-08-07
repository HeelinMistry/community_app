//
//  ProductRepository.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/29.
//

import Foundation
import CommunityCore
import UIKit

public final class ProductRepository: ProductRepositoryProtocol {
    
    private let networkClient: CommunityNetworkClient
    private let imagePreprocessor = ImagePreprocessor() 
    
    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
    }
    
    public func classify(_ images: [UIImage]) async throws -> (title: String, tags: [String]) {
        var allDetectedTags: Set<String> = []
        var suggestedProductTitle: String?
        
        for image in images { // Process the newly added images
            let result = try await classifyImage(image)
            allDetectedTags.formUnion(result.tags)
            suggestedProductTitle = result.title
        }
        return (suggestedProductTitle ?? "", Array(allDetectedTags))
    }
    
    /// Classifies a single image and extracts detected tags and a potential title suggestion.
    private func classifyImage(_ image: UIImage) async throws -> (title: String, tags: [String]) {
        let results = try await ImageClassifier.classify(image: image)
//        
        var tags: [String] = []
        var title: String = ""
        
        // Extract top identifiers/tags
        tags = results.map { $0.identifier }
        
        // Auto-suggest a title or category if high confidence is met
//        if let topMatch = results.first, topMatch.confidence > 0.4 {
        if let topMatch = results.first {
            title = topMatch.identifier.capitalized
        }
        return (title, tags)
    }
    
    public func create(_ product: AdvertiseProductRequest) async throws -> AdvertiseProductResponse {
        do {
            let dto: AdvertiseProductResponse = try await networkClient.fetch(from: CommunityEndpoint.advertise(product))
            return dto
        } catch {
            throw error
        }
    }
}
