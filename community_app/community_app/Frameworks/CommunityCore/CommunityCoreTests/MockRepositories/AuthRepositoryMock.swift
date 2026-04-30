//
//  AuthRepositoryMock.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import CommunityCore

// A mock repository to simulate network behavior
public actor AuthRepositoryMock: AuthRepositoryProtocol {
    
    var loginResult: Result<LoginResponse, Error>?
    var registerResult: Result<RegisterResponse, Error>?
    
    func setLoginResult(_ result: Result<LoginResponse, Error>) {
        self.loginResult = result
    }
    
    func setRegisterResult(_ result: Result<RegisterResponse, Error>) {
        self.registerResult = result
    }
    
    public func loginUser(loginRequest: LoginRequest) async throws -> LoginResponse {
        guard let result = loginResult else {
            fatalError("Result not set in AuthRepositoryMock")
        }
        
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    public func registerUser(registerRequest: RegisterRequest) async throws -> RegisterResponse {
        guard let result = registerResult else {
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
