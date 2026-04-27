//
//  DependencyContainer.swift
//  CommunityCommon
//
//  Created by Heelin Mistry on 2026/02/21.
//

import CommunityCore
import CommunityData
import CommunityUI

final class DependencyContainer {
    
    private let networkClient = CommunityNetworkClient()
    
    /// Initializes a new dependency container.
    public init() {}
    
    lazy var authRepository: AuthRepositoryProtocol = {
        return AuthRepository(networkClient: networkClient) 
    }()

    /// Creates and returns a `LoginViewModel`.
    public func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(authUseCases: self)
    }
}

extension DependencyContainer: AuthUseCasesProvider {
    
    /// Provides a use case for verifying user login.
    public var verifyLogin: VerifyUserLoginUseCaseProtocol {
        VerifyUserLoginUseCase(auth: authRepository)
    }
}
