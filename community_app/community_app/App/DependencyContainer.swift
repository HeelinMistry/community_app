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

/// A dependency injection container responsible for providing view models and other dependencies throughout the application.
@MainActor
final class DependencyContainer {
    private let router: NavigationRouter
    private let networkConfig: NetworkConfiguration
    private let networkClient: CommunityNetworkClient
    
    private var authRepository: AuthRepositoryProtocol!
    private var matchRepository: MatchRepositoryProtocol!
    
    private var dashboardViewModel: DashboardViewModel?
    
    /// Initializes the dependency container with a navigation router and sets up networking components based on the current environment.
    /// - Parameter router: The navigation router used for view transitions.
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
        self.matchRepository = MatchRepository(networkClient: networkClient)
    }
    
    /// Creates and returns a `LoginViewModel`.
    public func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(authUseCases: self, router: router)
    }
    
    /// Creates and returns a `RegistrationViewModel`.
    public func makeRegistrationViewModel() -> RegistrationViewModel {
        return RegistrationViewModel(authUseCases: self, router: router)
    }
    
    /// Creates and returns a `DashboardViewModel`.
    public func makeDashboardViewModel() -> DashboardViewModel {
        if let existing = dashboardViewModel {
            return existing
        }
        let newVM = DashboardViewModel(useCases: self, router: router)
        self.dashboardViewModel = newVM
        return newVM
    }
    
    /// Creates and returns a `CreateMatchViewModel`.
    public func makeCreateMatchViewModel() -> CreateMatchViewModel {
        // Inject the concrete MKLocalSearchService
        return CreateMatchViewModel(useCases: self, router: router, mapSearchService: MKLocalSearchService())
    }
    
    /// Creates and returns a `makeDetailMatchViewModel`.
    public func makeDetailMatchViewModel(_ match_id: String) -> MatchDetailsViewModel {
        return MatchDetailsViewModel(useCases: self, router: router, match_id: match_id, locationService: LocationService())
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

extension DependencyContainer: MatchUseCasesProvider {
    var matches: any MatchUseCaseProtocol {
        MatchUseCases(match: matchRepository)
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
    
    @MainActor
    public func makeDashboardView() -> AnyView {
        let viewModel = makeDashboardViewModel()
        return AnyView(DashboardView(viewModel: viewModel))
    }
    
    @MainActor
    public func makeCreateMatchView() -> AnyView {
        let viewModel = makeCreateMatchViewModel()
        return AnyView(CreateMatchView(viewModel: viewModel))
    }
    
    @MainActor
    public func makeDetailMatchView(_ match_id: String) -> AnyView {
        let viewModel = makeDetailMatchViewModel(match_id)
        return AnyView(MatchDetailsView(viewModel: viewModel))
    }
}
