//
//  AuthRepositoryProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

/// A protocol defining the contract for auth data retrieval.
///
/// The implementation should handle the orchestration between local persistence
/// and remote API calls.
public protocol AuthRepositoryProtocol: Sendable {

    /// Performs the login request.
    ///
    /// - Parameters:
    ///   - loginRequest: LoginRequest.
    /// - Returns: A `LoginResponse` containing data.
    /// - Throws: `NetworkError` if the API call fails or `DatabaseError` if caching fails.
    func verifyUserLogin(loginRequest: LoginRequest) async throws -> LoginResponse
}
