//
//  AuthRepositoryMock.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import CommunityCore

// A mock repository to simulate network behavior
actor AuthRepositoryMock: AuthRepositoryProtocol {
    // result is now protected by the actor
    var result: Result<LoginResponse, Error>?

    // You can add a helper to set the result
    func setResult(_ result: Result<LoginResponse, Error>) {
        self.result = result
    }

    func verifyUserLogin(loginRequest: LoginRequest) async throws -> LoginResponse {
        guard let result = result else {
            fatalError("Result not set in AuthRepositoryMock")
        }
        
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}
