//
//  AdvertiseProduct.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/08/05.
//

import Foundation

public enum ProductType: String, Sendable, Encodable, Decodable {
    case advertising
    case requesting
}

public nonisolated struct AdvertiseProductRequest: Sendable, Equatable, Encodable, Decodable {
    public let title: String
    public let description: String
    public var product_type: ProductType = .advertising
    public let tags: [String]
    public let latitude: Double
    public let longitude: Double
    public let service_radius: Double
    
    public init(
        title: String,
        description: String,
        tags: [String],
        latitude: Double,
        longitude: Double,
        service_radius: Double
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.latitude = latitude
        self.longitude = longitude
        self.service_radius = service_radius
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        description = try values.decode(String.self, forKey: .description)
        product_type = try values.decode(ProductType.self, forKey: .product_type)
        tags = try values.decode([String].self, forKey: .tags)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
        service_radius = try values.decode(Double.self, forKey: .service_radius)
    }
}

public nonisolated struct AdvertiseProductResponse: Sendable, Equatable, Encodable, Decodable {
    public let product_id: String
    
    public init(product_id: String) {
        self.product_id = product_id
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        product_id = try values.decode(String.self, forKey: .product_id)
    }
}

