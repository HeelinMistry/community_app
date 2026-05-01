//
//  DashboardRepositoryProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

/// A protocol defining the contract for dashboard data retrieval.
///
/// The implementation should handle the orchestration between local persistence
/// and remote API calls.
public protocol DashboardRepositoryProtocol: Sendable {

    func getMatches() async throws -> Matches
}

public protocol MatchUseCaseProtocol: Sendable {
    func userRelatedMatches() async throws -> Matches
}
