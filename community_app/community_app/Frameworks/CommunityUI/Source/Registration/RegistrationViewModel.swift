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
    var state: LoginViewState { get } // Reusing state for consistency
    var username: String { get set }
    var email: String { get set }
    var password: String { get set }
    var isLoading: Bool { get }
    
    func registerAttempt()
}

@MainActor
public final class RegistrationViewModel: RegistrationViewModelProtocol {
    @Published public private(set) var state: LoginViewState = .idle
    @Published public var username = ""
    @Published public var email = ""
    @Published public var password = ""
    
    public var isLoading: Bool { state == .loading }
    
    private let useCases: any AuthUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    public init(authUseCases: any AuthUseCasesProvider) {
        self.useCases = authUseCases
    }
    
    public func registerAttempt() {
        fetchTask?.cancel()
        state = .loading
        
        // You would add a register use case to your AuthUseCasesProvider
        fetchTask = Task {
            do {
                // Example call assuming a register use case exists
                // let response = try await useCases.registerUser.execute(...)
                try await Task.sleep(nanoseconds: 2_000_000_000) // Mock delay
                self.state = .idle
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}
