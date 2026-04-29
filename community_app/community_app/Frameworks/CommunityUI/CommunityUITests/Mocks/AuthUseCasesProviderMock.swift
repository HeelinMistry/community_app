//
//  AuthUseCasesProviderMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class AuthUseCasesMock: LoginUseCaseProtocol, RegisterUseCaseProtocol, @unchecked Sendable {
    
    var loginResult: Result<LoginResponse, Error>?
    var registerResult: Result<RegisterResponse, Error>?
    
    func execute(_ loginRequest: LoginRequest) async throws -> LoginResponse {
        if let result = loginResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MockVerifyUserLoginUseCase")
    }
    
    func execute(_ registerRequest: RegisterRequest) async throws -> RegisterResponse {
        if let result = registerResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MockVerifyUserLoginUseCase")
    }
}

// Mock for the provider that holds the use case
final class AuthUseCasesProviderMock: AuthUseCasesProvider, @unchecked Sendable {
    let mockAuthUseCases = AuthUseCasesMock()
    var loginUser: any LoginUseCaseProtocol { mockAuthUseCases }
    var registerUser: any RegisterUseCaseProtocol { mockAuthUseCases }
}
