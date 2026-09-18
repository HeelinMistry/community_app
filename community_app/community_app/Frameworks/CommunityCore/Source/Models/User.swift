//
//  User.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/08/12.
//

import Foundation

public nonisolated struct LocationRequest: Sendable, Equatable, Encodable, Decodable {
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
