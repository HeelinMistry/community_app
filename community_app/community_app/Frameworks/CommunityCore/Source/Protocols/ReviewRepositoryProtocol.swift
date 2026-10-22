//
//  ReviewRepositoryProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/10/13.
//

import UIKit

public protocol ReviewRepositoryProtocol: Sendable {

    func createReview(_ req: CreateReviewRequest, images: [UIImage]) async throws -> CreateReviewResponse
}

public protocol ReviewUseCasesProtocol: Sendable {
    
    func createProductReview(_ req: CreateReviewRequest, images: [UIImage]) async throws -> CreateReviewResponse
}
