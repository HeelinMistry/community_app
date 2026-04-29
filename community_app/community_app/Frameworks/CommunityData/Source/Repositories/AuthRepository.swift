//
//  AuthRepository.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import CommunityCore

public final class AuthRepository: AuthRepositoryProtocol {
    
    private let networkClient: CommunityNetworkClient
//    private let cache: WeatherCacheService

    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
    }
    
    public func loginUser(loginRequest: LoginRequest) async throws -> LoginResponse {
        do {
            let dto: LoginResponse = try await networkClient.fetch(from: CommunityEndpoint.login(loginRequest))
            return dto
        } catch {
            throw error
        }
    }
    
    public func registerUser(registerRequest: RegisterRequest) async throws -> RegisterResponse {
        do {
            let dto: RegisterResponse = try await networkClient.fetch(from: CommunityEndpoint.register(registerRequest))
            return dto
        } catch {
            throw error
        }
    }
}
