//
//  LoginViewModel.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/27.
//

import SwiftUI
import CommunityCore
import Combine

@MainActor
public protocol LoginViewModelProtocol: ObservableObject {
    var state: LoginViewState { get }
    var username: String { get set }
    var password: String { get set }
    var isLoading: Bool { get } 
    
    func login()
    func showRegistration()
}

@MainActor
public final class LoginViewModel: LoginViewModelProtocol {
    
    @Published public private(set) var state: LoginViewState = .idle
    @Published public var username = ""
    @Published public var password = ""
    
    public var isLoading: Bool {
        state == .loading
    }
    
    private let router: NavigationRouter
    private let useCases: any AuthUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    public init(
        authUseCases: any AuthUseCasesProvider,
        router: NavigationRouter
    ) {
        self.useCases = authUseCases
        self.router = router
    }
    
    public func login() {
        fetchTask?.cancel()
        state = .loading
        let loginRequest = LoginRequest(username: username, password: password)
        fetchTask = Task {
            do {
                let response: LoginResponse = try await useCases.verifyLogin.execute(loginRequest)
                if !Task.isCancelled {
                    self.state = .success(response)
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                    router.alert(
                        title: "Error",
                        message: "Unable to login. Please try again."
                    )
                }
            }
        }
    }
    
    public func showRegistration() {
        router.present(sheet: .registration)
    }
}
