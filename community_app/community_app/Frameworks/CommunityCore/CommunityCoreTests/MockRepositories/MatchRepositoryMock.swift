//
//  DashboardRepositoryMock.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore

// A mock repository to simulate network behavior
public actor MatchRepositoryMock: MatchRepositoryProtocol {
    
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
    
    var createMatchesResult: Result<CreateMatchResponse, Error>?
    
    func setCreateMatchResult(_ result: Result<CreateMatchResponse, Error>) {
        self.createMatchesResult = result
    }
    
    public func createMatch(_ createMatchRequest: CreateMatchRequest) async throws -> CreateMatchResponse {
        guard let result = createMatchesResult else {
            fatalError("Result not set in RepositoryMock")
        }
        
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    var matchDetailResult: Result<MatchDetailResponse, Error>?
    
    func setMatchDetailResult(_ result: Result<MatchDetailResponse, Error>) {
        self.matchDetailResult = result
    }
    
    public func getMatch(_ matchRequest: MatchDetailRequest) async throws -> MatchDetailResponse {
        guard let result = matchDetailResult else {
            fatalError("Result not set in RepositoryMock")
        }
        
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    var participationResult: Result<ParticipationResponse, Error>?
    
    func setParticipationResult(_ result: Result<ParticipationResponse, Error>) {
        self.participationResult = result
    }
    public func toggleParticipation(_ matchRequest: MatchDetailRequest) async throws -> ParticipationResponse {
        guard let result = participationResult else {
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
