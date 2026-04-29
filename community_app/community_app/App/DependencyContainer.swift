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
    private let router: NavigationRouter
    private let networkConfig: NetworkConfiguration
    private let networkClient: CommunityNetworkClient
    
    private var authRepository: AuthRepositoryProtocol!
    
    public init(router: NavigationRouter) {
        self.router = router
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
        return LoginViewModel(authUseCases: self, router: router)
    }
    
    /// Creates and returns a `LoginViewModel`.
    public func makeRegistrationViewModel() -> RegistrationViewModel {
        return RegistrationViewModel(authUseCases: self, router: router)
    }
}

extension DependencyContainer: AuthUseCasesProvider {
    var loginUser: any LoginUseCaseProtocol {
        AuthUseCases(auth: authRepository)
    }
    
    var registerUser: any RegisterUseCaseProtocol {
        AuthUseCases(auth: authRepository)
    }
}

extension DependencyContainer: ViewFactory {
    @MainActor
    public func makeLoginView() -> AnyView {
        let viewModel = makeLoginViewModel()
        return AnyView(LoginView(viewModel: viewModel))
    }

    @MainActor
    public func makeRegistrationView() -> AnyView {
        let viewModel = makeRegistrationViewModel()
        return AnyView(RegistrationView(viewModel: viewModel))
    }
}
