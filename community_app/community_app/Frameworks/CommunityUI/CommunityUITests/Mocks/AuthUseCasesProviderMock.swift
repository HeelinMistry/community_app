//
//  AuthUseCasesProviderMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import CommunityCore
@testable import CommunityUI

// Mock for the VerifyUserLoginUseCase
final class MockVerifyUserLoginUseCase: VerifyUserLoginUseCaseProtocol, @unchecked Sendable {
    var result: Result<LoginResponse, Error>?
    
    func execute(_ loginRequest: LoginRequest) async throws -> LoginResponse {
        if let result = result {
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
    let mockVerifyLogin = MockVerifyUserLoginUseCase()
    var verifyLogin: any VerifyUserLoginUseCaseProtocol { mockVerifyLogin }
}
