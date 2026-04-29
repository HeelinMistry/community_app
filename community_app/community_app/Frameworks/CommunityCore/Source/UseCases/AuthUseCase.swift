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
public protocol AuthUseCaseProtocol: Sendable {
    /// Executes the login verification process with the given login request.
    /// - Parameter loginRequest: The `LoginRequest` containing user credentials.
    /// - Returns: A `Bool` indicating the success or failure of the login attempt.
    /// - Throws: An error if the login verification fails.
    func loginUser(_ loginRequest: LoginRequest) async throws -> LoginResponse
    func registerUser(_ registerRequest: LoginRequest) async throws -> LoginResponse
}

public final class AuthUseCases: LoginUseCaseProtocol, RegisterUseCaseProtocol {
    private let auth: any AuthRepositoryProtocol

    public init(auth: any AuthRepositoryProtocol) {
        self.auth = auth
    }

    public func execute(_ request: LoginRequest) async throws -> LoginResponse {
        do {
            let loginResponse = try await auth.loginUser(loginRequest: request)
            return (loginResponse)
        } catch {
            throw error
        }
    }
    
    public func execute(_ request: RegisterRequest) async throws -> RegisterResponse {
        do {
            let registerRequest = try await auth.registerUser(registerRequest: request)
            return (registerRequest)
        } catch {
            throw error
        }
    }
}
