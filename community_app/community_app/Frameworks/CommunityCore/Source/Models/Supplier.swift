//
//  Supplier.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/10.
//

import Foundation

/// A typealias for an array of SupplierResponse objects.
public typealias Suppliers = [SupplierResponse]

public nonisolated struct SupplierResponse: Sendable, Equatable, Encodable, Decodable {
    public let id: String
    public let business_name: String
    public let description: String
    public let category: String
    public let distance_km: Double
    public let latitude: Double
    public let longitude: Double
    public let is_creator: Bool
    
    public init(id: String, user_id: String, business_name: String, description: String, category: String, distance_km: Double, latitude: Double, longitude: Double, is_creator: Bool) {
        self.id = id
        self.business_name = business_name
        self.description = description
        self.category = category
        self.distance_km = distance_km
        self.latitude = latitude
        self.longitude = longitude
        self.is_creator = is_creator
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.business_name = try container.decode(String.self, forKey: .business_name)
        self.description = try container.decode(String.self, forKey: .description)
        self.category = try container.decode(String.self, forKey: .category)
        self.distance_km = try container.decode(Double.self, forKey: .distance_km)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.is_creator = try container.decode(Bool.self, forKey: .is_creator)
    }
}
