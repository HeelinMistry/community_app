//
//  CreateSupplier.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/07/12.
//

import Foundation

public nonisolated struct CreateSupplierRequest: Sendable, Equatable, Encodable, Decodable {
    public let business_name: String
    public let description: String
    public let category: String
    public let latitude: Double
    public let longitude: Double
    public let service_radius: Double
    
    public init(
        business_name: String,
        description: String,
        category: String,
        latitude: Double,
        longitude: Double,
        service_radius: Double
    ) {
        self.business_name = business_name
        self.description = description
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.service_radius = service_radius
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        business_name = try values.decode(String.self, forKey: .business_name)
        description = try values.decode(String.self, forKey: .description)
        category = try values.decode(String.self, forKey: .category)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
        service_radius = try values.decode(Double.self, forKey: .service_radius)
    }
}

public nonisolated struct CreateSupplierResponse: Sendable, Equatable, Encodable, Decodable {
    public let supplier_id: String
    
    public init(supplier_id: String) {
        self.supplier_id = supplier_id
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        supplier_id = try values.decode(String.self, forKey: .supplier_id)
    }
}
