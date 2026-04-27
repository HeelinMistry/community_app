//
//  VerifyLoginUseCase.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation

/// A protocol defining the contract for verifying user login.
///
/// This protocol is `Sendable` to ensure it can be safely used across concurrency domains.
public protocol VerifyUserLoginUseCaseProtocol: Sendable {
    /// Executes the login verification process with the given login request.
    /// - Parameter loginRequest: The `LoginRequest` containing user credentials.
    /// - Returns: A `Bool` indicating the success or failure of the login attempt.
    /// - Throws: An error if the login verification fails.
    func execute(_ loginRequest: LoginRequest) async throws -> LoginResponse
}

/// A concrete implementation of `VerifyUserLoginUseCaseProtocol` responsible for verifying user login.
///
/// This use case interacts with an `AuthRepositoryProtocol` to perform the actual authentication.
public final class VerifyUserLoginUseCase: VerifyUserLoginUseCaseProtocol {
    private let auth: any AuthRepositoryProtocol

    /// Initializes a new `VerifyUserLoginUseCase` with a given authentication repository.
    /// - Parameter auth: An object conforming to `AuthRepositoryProtocol` that handles authentication logic.
    public init(
        auth: any AuthRepositoryProtocol
    ) {
        self.auth = auth
    }

    /// Executes the login verification process.
    ///
    /// This method forwards the `loginRequest` to the underlying `AuthRepositoryProtocol`
    /// to verify the user's credentials.
    /// - Parameter loginRequest: The `LoginRequest` containing the user's login information.
    /// - Returns: `true` if the login is successful, `false` otherwise.
    /// - Throws: An error if the authentication repository encounters an issue.
    public func execute(_ loginRequest: LoginRequest) async throws -> LoginResponse {
        do {
            print(loginRequest)
            let loginResponse = try await auth.verifyUserLogin(loginRequest: loginRequest)
//            Log.networking.json("Successfully fetched login", loginRequest) // Uncomment and ensure Log is available if needed.
            return (loginResponse)
        } catch {
            // Re-throw the error to be handled by the caller.
            throw error
        }
    }
}
