//
//  Product.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/08/12.
//

import Foundation

/// A typealias for an array of SupplierResponse objects.
public typealias Products = [ProductResponse]

public nonisolated struct ProductResponse: Sendable, Equatable, Encodable, Decodable {
    public let id: String
    public let title: String
    public let description: String
    public let tags: [String]
    public let distance_km: Double
    public let latitude: Double
    public let longitude: Double
    public let is_creator: Bool
    public let is_available: Bool
    
    public init(id: String, user_id: String, title: String, description: String, tags: [String], distance_km: Double, latitude: Double, longitude: Double, is_creator: Bool, is_available: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.tags = tags
        self.distance_km = distance_km
        self.latitude = latitude
        self.longitude = longitude
        self.is_creator = is_creator
        self.is_available = is_available
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.distance_km = try container.decode(Double.self, forKey: .distance_km)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.is_creator = try container.decode(Bool.self, forKey: .is_creator)
        self.is_available = try container.decode(Bool.self, forKey: .is_available)
    }
}
