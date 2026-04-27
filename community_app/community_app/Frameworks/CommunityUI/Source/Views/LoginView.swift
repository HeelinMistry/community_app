//
//  CommunityLogin.swift
//  CommunityUI
//
//

import SwiftUI

public struct LoginView<T: LoginViewModelProtocol>: View {
    @StateObject private var viewModel: T
    
    public init(viewModel: T) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            Assets.theme.inputBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                BrandLogo(
                    "PITCH",
                    secondaryString: "PASS"
                )
                PrimaryTextInput(
                    label: "Username",
                    placeholder: "e.g. test_user",
                    text: $viewModel.username
                )
                PrimaryTextInput(
                    label: "Password",
                    placeholder: "e.g. password123",
                    text: $viewModel.password
                )
                
                PrimaryButton("Login") {
                    viewModel.loginAttempt()
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack(spacing: 4) {
                    Text("NEW TO THE COMMUNITY?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    SecondaryButton("Register") {
                        // Action
                    }
                }
            }
            .padding(30)
            .background(Assets.theme.inputBackground)
            .cornerRadius(30)
            .padding(.horizontal, 20)
        }
    }
}
