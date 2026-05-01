//
//  DashboardRepository.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore

public final class MatchRepository: MatchRepositoryProtocol {
    
    private let networkClient: CommunityNetworkClient
    
    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
    }
    
    public func getMatches() async throws -> Matches {
        do {
            let dto: Matches = try await networkClient.fetch(from: CommunityEndpoint.matches)
            return dto
        } catch {
            throw error
        }
    }
    
    public func createMatch(_ request: CreateMatchRequest) async throws -> CreateMatchResponse {
        do {
            let dto: CreateMatchResponse = try await networkClient.fetch(from: CommunityEndpoint.createMatch(request))
            return dto
        } catch {
            throw error
        }
    }
}
