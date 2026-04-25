//
//  CommunityLogin.swift
//  CommunityUI
//
//

import SwiftUI
import UI

public struct LoginView: View {
    @State private var username: String = ""
    
    public init() { }
    
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
                    placeholder: "e.g. striker99",
                    text: $username
                )
                PrimaryButton("Password") {
                    print("Button Tapped")
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

#Preview {
    LoginView()
}
