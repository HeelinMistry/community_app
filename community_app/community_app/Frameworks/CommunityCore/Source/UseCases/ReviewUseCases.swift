//
//  ReviewUseCases.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/10/13.
//

import UIKit

public final class ReviewUseCases: ReviewUseCasesProtocol {
    
    private let review: any ReviewRepositoryProtocol
    private let imageCache: any ImageCacheProtocol
    
    public init(review: any ReviewRepositoryProtocol, imageCache: any ImageCacheProtocol) {
        self.review = review
        self.imageCache = imageCache
    }
    
    public func createProductReview(_ req: CreateReviewRequest) async throws -> CreateReviewResponse {
        do {
            let reviewResponse = try await review.createReview(req)
            return reviewResponse
        } catch {
            throw error
        }
    }
}
