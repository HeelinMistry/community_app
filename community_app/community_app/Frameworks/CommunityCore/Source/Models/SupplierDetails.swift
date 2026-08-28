//
//  SupplierDetails.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/07/24.
//

import Foundation

public struct SupplierDetailResponse: Codable, Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let business_name: String
    public let description: String
    public let latitude: Double
    public let longitude: Double
    public let service_radius: Double
    public let category: String

    public init(id: String = UUID().uuidString,
                business_name: String = "Sample Business",
                description: String = "A detailed description of the sample business, providing insights into its services and mission.",
                latitude: Double = -25.7479, // Example: Pretoria latitude
                longitude: Double = 28.2293, // Example: Pretoria longitude
                service_radius: Double = 5.0,
                category: String = "General Services") {
        self.id = id
        self.business_name = business_name
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.service_radius = service_radius
        self.category = category
    }

    // Explicitly declare Equatable conformance as nonisolated to resolve the compiler error.
    // This forces the conformance to not be tied to any specific actor, satisfying Sendable requirements.
    nonisolated public static func == (lhs: SupplierDetailResponse, rhs: SupplierDetailResponse) -> Bool {
        lhs.id == rhs.id &&
        lhs.business_name == rhs.business_name &&
        lhs.description == rhs.description &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.service_radius == rhs.service_radius &&
        lhs.category == rhs.category
    }
}
