//
//  ProductDetails.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/28.
//

import Foundation

public struct ProductDetailResponse: Codable, Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let tags: [String]
    public let product_type: String
    
    public let latitude: Double
    public let longitude: Double
    public let service_radius: Double
    public let is_creator: Bool
    public let is_available: Bool
    public let image_urls: [String]
    
    public init(id: String = UUID().uuidString,
                title: String = "Sample Business",
                description: String = "A detailed description of the sample business, providing insights into its services and mission.",
                tags: [String] = ["menu", "food", "drink", "snack"],
                product_type: String = "advertising",
                latitude: Double = -25.7479, // Example: Pretoria latitude
                longitude: Double = 28.2293, // Example: Pretoria longitude
                service_radius: Double = 5.0,
                is_creator: Bool = false,
                is_available: Bool = true,
                image_urls: [String] = ["/static/uploads/p_8a6106e1.jpg"]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.tags = tags
        self.product_type = product_type
        self.latitude = latitude
        self.longitude = longitude
        self.service_radius = service_radius
        self.is_creator = is_creator
        self.is_available = is_available
        self.image_urls = image_urls
    }
    
    // Explicitly declare Equatable conformance as nonisolated to resolve the compiler error.
    // This forces the conformance to not be tied to any specific actor, satisfying Sendable requirements.
    nonisolated public static func == (lhs: ProductDetailResponse, rhs: ProductDetailResponse) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.tags == rhs.tags &&
        lhs.product_type == rhs.product_type &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.service_radius == rhs.service_radius &&
        lhs.is_creator == rhs.is_creator &&
        lhs.is_available == rhs.is_available &&
        lhs.image_urls == rhs.image_urls
    }
}
