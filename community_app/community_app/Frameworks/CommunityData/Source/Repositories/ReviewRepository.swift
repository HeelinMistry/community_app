//
//  ReviewRepository.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/10/13.
//


import Foundation
import CommunityCore
import UIKit

public final class ReviewRepository: ReviewRepositoryProtocol {
    
    private let networkClient: CommunityNetworkClient
    
    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
    }
    
    public func createReview(_ req: CreateReviewRequest) async throws -> CreateReviewResponse {
        do {
            let dto: CreateReviewResponse = try await networkClient.fetch(from: CommunityEndpoint.createReview(req))
            return dto
        } catch {
            throw error
        }
    }
    
}
