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
import SwiftUI

@MainActor
final class DependencyContainer {
    private let networkConfig: NetworkConfiguration
    private let networkClient: CommunityNetworkClient
    
    private var authRepository: AuthRepositoryProtocol!
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
        self.networkClient = .init(networkConfig: networkConfig)
        self.authRepository = AuthRepository(networkClient: networkClient)
    }
    
    /// Creates and returns a `LoginViewModel`.
    public func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(authUseCases: self)
    }
    
    /// Creates and returns a `LoginViewModel`.
    public func makeRegistrationViewModel() -> RegistrationViewModel {
        return RegistrationViewModel(authUseCases: self)
    }
}

extension DependencyContainer: AuthUseCasesProvider {
    
    /// Provides a use case for verifying user login.
    public var verifyLogin: VerifyUserLoginUseCaseProtocol {
        VerifyUserLoginUseCase(auth: authRepository)
    }
}

extension DependencyContainer: ViewFactory {
    @MainActor
    public func makeLoginView() -> AnyView {
        let viewModel = LoginViewModel(authUseCases: self)
        return AnyView(LoginView(viewModel: viewModel))
    }

    @MainActor
    public func makeRegistrationView() -> AnyView {
        let viewModel = RegistrationViewModel(authUseCases: self)
        return AnyView(RegistrationView(viewModel: viewModel))
    }
}
