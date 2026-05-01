//
//  RegistrationView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/28.
//

import SwiftUI
import CommunityCore

public struct RegistrationView<T: RegistrationViewModelProtocol>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T
    
    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Assets.theme.inputBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    PrimaryTextInput(
                        label: "Username",
                        placeholder: "e.g. newUser",
                        text: $viewModel.username,
                        errorMessage: viewModel.validationErrors["username"]
                    )
                    PrimaryTextInput(
                        label: "Display Name",
                        placeholder: "e.g. Sparkles",
                        text: $viewModel.displayName,
                        errorMessage: viewModel.validationErrors["displayName"]
                    )
                    PrimaryTextInput(
                        label: "Email",
                        placeholder: "e.g. hello@community.com",
                        text: $viewModel.email,
                        errorMessage: viewModel.validationErrors["email"]
                    )
                    PrimaryTextInput(
                        label: "Cell Number",
                        placeholder: "e.g. 0726759182",
                        text: $viewModel.cellNumber,
                        errorMessage: viewModel.validationErrors["cellNumber"]
                    )
                    PrimaryTextInput(
                        label: "Password",
                        placeholder: "********",
                        text: $viewModel.password,
                        errorMessage: viewModel.validationErrors["password"],
                        isSecure: true
                    )
                    PrimaryTextInput(
                        label: "Confirm Password",
                        placeholder: "********",
                        text: $viewModel.confirmPassword,
                        errorMessage: viewModel.validationErrors["confirm"],
                        isSecure: true
                    )
                    
                    PrimaryButton("Create Account") {
//                        if viewModel.isFormValid {
                        viewModel.register()
//                        }
                    }
                    .disabled(viewModel.state.isLoading)
                }
                .padding(30)
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { router.sheet = nil }
                }
            }
        }
    }
}
