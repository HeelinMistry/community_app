//
//  MapSearchServiceMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/07.
//

import CommunityCore
import MapKit

// Mock for MapSearchServiceProtocol
class MockMapSearchService: MapSearchServiceProtocol {
    var searchResult: Result<[MKMapItem], Error>?
    var lastQuery: String?
    
    func search(query: String) async throws -> [MKMapItem] {
        lastQuery = query
        if let result = searchResult {
            switch result {
            case .success(let items):
                return items
            case .failure(let error):
                throw error
            }
        }
        return [] // Default to no results if not configured
    }
}
