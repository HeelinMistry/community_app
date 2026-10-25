//
//  Review.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/10/06.
//

import Foundation

public nonisolated struct CreateReviewRequest: Sendable, Equatable, Encodable, Decodable {
    public let id: String
    public let comment: String?
    public let rating: Double
    public let latitude: Double
    public let longitude: Double
    
    public init(
        id: String = "p_678ty768",
        comment: String = "Wonderful",
        rating: Double = 5.0,
        latitude: Double = 0.0,
        longitude: Double = 0.0
    ) {
        self.id = id
        self.comment = comment
        self.rating = rating
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        comment = try values.decode(String.self, forKey: .comment)
        rating = try values.decode(Double.self, forKey: .rating)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
    }
}

public nonisolated struct CreateReviewResponse: Sendable, Equatable, Encodable, Decodable {
    public let review_id: String
    
    public init(review_id: String) {
        self.review_id = review_id
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        review_id = try values.decode(String.self, forKey: .review_id)
    }
}
