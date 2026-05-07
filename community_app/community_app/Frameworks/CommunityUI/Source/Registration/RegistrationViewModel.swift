//
//  RegistrationViewModel.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/28.
//

import Combine
import Foundation
import CommunityCore

@MainActor
public protocol RegistrationViewModelProtocol: ValidatableViewModel {
    var username: String { get set }
    var displayName: String { get set }
    var email: String { get set }
    var cellNumber: String { get set }
    var password: String { get set }
    var confirmPassword: String { get set }
    
    func register()
}

@MainActor
public final class RegistrationViewModel: RegistrationViewModelProtocol {
    @Published public private(set) var state: ViewState<RegisterResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]
    @Published public var username = ""
    @Published public var displayName = ""
    @Published public var email = ""
    @Published public var cellNumber = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    
    public func isFormValid(step: Int? = nil) -> Bool {
        incompleteForm()
        return validationErrors.isEmpty
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
    
    public func register() {
        fetchTask?.cancel()
        state = .loading
//        let registerRequest = RegisterRequest(
//            username: username,
//            displayName: displayName,
//            email: email,
//            cellNumber: cellNumber,
//            password: password
//        )
        let registerRequest = RegisterRequest(
            username: "test_user",
            displayName: "Test User",
            email: "test@test.com",
            cellNumber: "0738466576",
            password: "password123"
        )
        fetchTask = Task {
            do {
                let response: RegisterResponse = try await useCases.registerUser.execute(registerRequest)
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
        if username.trimmingCharacters(in: .whitespaces).isEmpty { errors["username"] = "Username is for your login" }
        if displayName.isEmpty { errors["displayName"] = "Display name is what the public can see" }
        if !isValidEmail(email) { errors["email"] = "Check your email format" }
        if !isValidPhone(cellNumber) { errors["cellNumber"] = "Check your cell number format" }
        if !isValidPassword(password) { errors["password"] = "Password is kinda required" }
        if !isValidConfirm(password, confirm: confirmPassword) { errors["confirm"] = "Passwords do not match" }
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
