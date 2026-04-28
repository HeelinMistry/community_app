//
//  DependencyContainer.swift
//  CommunityCommon
//
//  Created by Heelin Mistry on 2026/02/21.
//

import CommunityCore
import CommunityData
import CommunityUI
import Foundation

@MainActor
final class DependencyContainer {
    private let networkConfig: NetworkConfiguration
    private let networkClient: CommunityNetworkClient
    
    /// Initializes a new dependency container.
    public init() {
        
        let environment: AppEnvironment
        
#if DEBUG
        environment = .debug
#else
        environment = .release
#endif
        
        self.networkConfig = .init(
            baseURL: environment.baseURL,
            shouldLogSensitiveData: environment.shouldLog
        )
        networkClient = .init(networkConfig: networkConfig)
    }
    
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
