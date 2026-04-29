//
//  Untitled.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/28.
//

import Combine
import Foundation
import CommunityCore

@MainActor
public protocol RegistrationViewModelProtocol: ObservableObject {
    var state: RegisterViewState { get }
    var username: String { get set }
    var displayName: String { get set }
    var email: String { get set }
    var cellNumber: String { get set }
    var password: String { get set }
    var confirmPassword: String { get set }
    var isLoading: Bool { get }
    
    func register()
}

@MainActor
public final class RegistrationViewModel: RegistrationViewModelProtocol {
    @Published public private(set) var state: RegisterViewState = .idle
    @Published public var username = ""
    @Published public var displayName = ""
    @Published public var email = ""
    @Published public var cellNumber = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    
    public var isLoading: Bool { state == .loading }
    
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
    
    public func register() {
        fetchTask?.cancel()
        state = .loading
        let registerRequest = RegisterRequest(
            username: username,
            displayName: displayName,
            email: email,
            cellNumber: cellNumber,
            password: password,
            confirmPassword: confirmPassword
        )
        fetchTask = Task {
            do {
                let response: RegisterResponse = try await useCases.registerUser.execute(registerRequest)
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
}
