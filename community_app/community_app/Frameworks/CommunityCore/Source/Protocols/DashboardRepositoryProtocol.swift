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

    /// Performs the login request.
    ///
    /// - Parameters:
    ///   - loginRequest: LoginRequest.
    /// - Returns: A `LoginResponse` containing data.
    /// - Throws: `NetworkError` if the API call fails or `DatabaseError` if caching fails.
    func getMatches() async throws -> MatchResponse
}

public protocol MatchUseCaseProtocol: Sendable {
    func execute() async throws -> MatchResponse
}
