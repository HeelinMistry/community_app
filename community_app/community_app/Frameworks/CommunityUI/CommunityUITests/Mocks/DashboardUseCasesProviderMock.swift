//
//  DashboardUseCasesProviderMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class DashboardUseCasesMock: MatchUseCaseProtocol, @unchecked Sendable {
    
    var matchResult: Result<MatchResponse, Error>?
    
    func execute() async throws -> MatchResponse {
        if let result = matchResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
}

// Mock for the provider that holds the use case
final class DashboardUseCasesProviderMock: DashboardUseCasesProvider, @unchecked Sendable {
    let mockDashboardUseCases = DashboardUseCasesMock()
    var matches: any MatchUseCaseProtocol { mockDashboardUseCases }
}
