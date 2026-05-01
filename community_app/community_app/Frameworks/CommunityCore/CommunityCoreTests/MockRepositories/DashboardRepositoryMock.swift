//
//  DashboardRepositoryMock.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore

// A mock repository to simulate network behavior
public actor DashboardRepositoryMock: DashboardRepositoryProtocol {
    
    var matchesResult: Result<Matches, Error>?
    
    func setMatchResult(_ result: Result<Matches, Error>) {
        self.matchesResult = result
    }
    
    public func getMatches() async throws -> Matches {
        guard let result = matchesResult else {
            fatalError("Result not set in RepositoryMock")
        }
        
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}
