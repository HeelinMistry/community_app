//
//  MapSearchServiceProtocol.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/07.
//

import MapKit

// MARK: - New Map Search Service Protocol and Implementation

/// Protocol for a map search service, allowing for mocking in tests.
public protocol MapSearchServiceProtocol {
    /// Searches for map items based on a given query string.
    /// - Parameter query: The natural language query string to search for.
    /// - Returns: An array of `MKMapItem` objects matching the query.
    /// - Throws: An error if the search operation fails.
    func search(query: String) async throws -> [MKMapItem]
}
