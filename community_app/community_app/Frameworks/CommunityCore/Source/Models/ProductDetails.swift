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

    public init(
        id: String = UUID().uuidString,
        title: String = "Sample Business",
        description: String = "A detailed description of the sample business, providing insights into its services and mission.",
        tags: [String] = ["menu", "food", "drink", "snack"],
        product_type: String = "advertising",
        latitude: Double = -25.7479,
        longitude: Double = 28.2293,
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

    public nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        tags = try container.decode([String].self, forKey: .tags)
        product_type = try container.decode(String.self, forKey: .product_type)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        service_radius = try container.decode(Double.self, forKey: .service_radius)
        is_creator = try container.decode(Bool.self, forKey: .is_creator)
        is_available = try container.decode(Bool.self, forKey: .is_available)
        image_urls = try container.decode([String].self, forKey: .image_urls)
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(tags, forKey: .tags)
        try container.encode(product_type, forKey: .product_type)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(service_radius, forKey: .service_radius)
        try container.encode(is_creator, forKey: .is_creator)
        try container.encode(is_available, forKey: .is_available)
        try container.encode(image_urls, forKey: .image_urls)
    }

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

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case tags
        case product_type
        case latitude
        case longitude
        case service_radius
        case is_creator
        case is_available
        case image_urls
    }
}
