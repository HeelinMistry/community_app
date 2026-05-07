//
//  MKLocalSearchService.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/07.
//

import MapKit
import CommunityCore

/// Concrete implementation of MapSearchServiceProtocol using MKLocalSearch.
public final class MKLocalSearchService: MapSearchServiceProtocol, Sendable {
    /// Initializes a new instance of the `MKLocalSearchService`.
    public nonisolated init() {}
    
    /// Searches for map items using `MKLocalSearch` based on a given query string.
    /// - Parameter query: The natural language query string to search for.
    /// - Returns: An array of `MKMapItem` objects matching the query.
    /// - Throws: An error if the `MKLocalSearch` operation fails.
    public func search(query: String) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }
}
