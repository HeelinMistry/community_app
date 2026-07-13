//
//  Supplier.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/10.
//

import Foundation

/// A typealias for an array of SupplierResponse objects.
public typealias Suppliers = [SupplierResponse]

public nonisolated struct SupplierRequest: Sendable, Equatable, Encodable, Decodable {
    public let lat: Double
    public let lon: Double
    
    public init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lat = try container.decode(Double.self, forKey: .lat)
        self.lon = try container.decode(Double.self, forKey: .lon)
    }
    
    public var convertCoordinateToReal: (String, String) {
        return (String(format: "%.6f", lat), String(format: "%.6f", lon))
        
    }
}

public nonisolated struct SupplierResponse: Sendable, Equatable, Encodable, Decodable {
    public let id: String
    public let business_name: String
    public let description: String
    public let category: String
    public let distance_km: Double
    
    public init(id: String, user_id: String, business_name: String, description: String, category: String, distance_km: Double) {
        self.id = id
        self.business_name = business_name
        self.description = description
        self.category = category
        self.distance_km = distance_km
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.business_name = try container.decode(String.self, forKey: .business_name)
        self.description = try container.decode(String.self, forKey: .description)
        self.category = try container.decode(String.self, forKey: .category)
        self.distance_km = try container.decode(Double.self, forKey: .distance_km)
    }
}
