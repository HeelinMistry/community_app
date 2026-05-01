//
//  CreateMatchViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/01.
//

import Combine
import Foundation
import CommunityCore

@MainActor
public protocol CreateMatchViewModelProtocol: ValidatableViewModel {
    var title: String { get set }
    var sport: String { get set }
    var duration: String { get set }
    var date_event: String { get set }
    var time: String { get set }
    var location: String { get set }
    var roster_size: String { get set }
    var cost: String { get set }
    
    func create()
}

@MainActor
public final class CreateMatchViewModel: CreateMatchViewModelProtocol {
    @Published public private(set) var state: ViewState<Matches> = .idle
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public var title = ""
    @Published public var sport = ""
    @Published public var duration = ""
    @Published public var date_event = ""
    @Published public var time = ""
    @Published public var location = ""
    @Published public var roster_size = ""
    @Published public var cost = ""
    
    public var isFormValid: Bool {
        incompleteForm()
        return validationErrors.isEmpty
    }
    
    private let router: NavigationRouter
    private let useCases: any DashboardUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    public init(
        useCases: any DashboardUseCasesProvider,
        router: NavigationRouter
    ) {
        self.useCases = useCases
        self.router = router
    }
    
    public func create() {
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                let response: Matches = try await useCases.matches.userRelatedMatches()
                if !Task.isCancelled {
                    self.state = .success(response)
                    router.sheet = nil
                }
            } catch {
                if !Task.isCancelled {
                    self.validationErrors["username"] = "\(error.localizedDescription)"
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func incompleteForm() {
        var errors: [String: String] = [:]
        self.validationErrors = errors
    }
    
    // MARK: - Validation Helpers
    
    private func isValidPassword(_ password: String) -> Bool {
        password.count > 4
    }
    
    private func isValidConfirm(_ password: String, confirm: String) -> Bool {
        password == confirm
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        // Simple regex for 10+ digits; adjust based on your region's requirements
        let phoneRegEx = "^[0-9]{10,15}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone)
    }
}
