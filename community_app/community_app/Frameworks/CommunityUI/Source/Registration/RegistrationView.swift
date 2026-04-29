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
                    PrimaryTextInput(label: "Username", placeholder: "e.g. newUser", text: $viewModel.username)
                    PrimaryTextInput(label: "Display Name", placeholder: "e.g. Sparkles", text: $viewModel.displayName)
                    PrimaryTextInput(label: "Email", placeholder: "e.g. hello@community.com", text: $viewModel.email)
                    PrimaryTextInput(label: "Cell Number", placeholder: "e.g. 0726759182", text: $viewModel.cellNumber)
                    PrimaryTextInput(label: "Password", placeholder: "********", text: $viewModel.password)
                    PrimaryTextInput(label: "Confirm Password", placeholder: "********", text: $viewModel.confirmPassword)
                    
                    PrimaryButton("Create Account") {
                        viewModel.register()
                    }
                    .disabled(viewModel.isLoading)
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
