//
//  MatchUseCasesProviderMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class MatchUseCasesMock: MatchUseCaseProtocol, @unchecked Sendable {

    var matchResult: Result<Matches, Error>?
    func userRelatedMatches() async throws -> Matches {
        if let result = matchResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
    var createMatchResult: Result<CreateMatchResponse, Error>?
    func userCreateMatch(_ request: CreateMatchRequest) async throws -> CreateMatchResponse {
        if let result = createMatchResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
    var matchDetailsResult: Result<MatchDetailResponse, Error>?
    func matchDetail(_ request: MatchDetailRequest) async throws -> MatchDetailResponse {
        if let result = matchDetailsResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
    var participationResult: Result<ParticipationResponse, Error>?
    func toggleParticipation(_ matchRequest: MatchDetailRequest) async throws -> ParticipationResponse {
        if let result = participationResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
}

// Mock for the provider that holds the use case
final class MatchUseCasesProviderMock: MatchUseCasesProvider, @unchecked Sendable {
    let mockUseCases = MatchUseCasesMock()
    var matches: any MatchUseCaseProtocol { mockUseCases }
}
