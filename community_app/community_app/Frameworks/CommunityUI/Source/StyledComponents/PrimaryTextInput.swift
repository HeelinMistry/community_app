//
//  PrimaryTextInput.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/25.
//

import SwiftUI

/// A primary text input field with a label and a placeholder, designed for user data entry.
/// It features a distinct background and border styling.
public struct PrimaryTextInput: View {
    /// The label text displayed above the input field, typically uppercased and gray.
    let label: String
    /// The placeholder text shown inside the input field when it's empty.
    let placeholder: String
    let errorMessage: String?
    let isSecure: Bool
    /// A binding to the string value that the text field edits.
    @Binding var text: String
    
    /// Creates a primary text input field.
    /// - Parameters:
    ///   - label: The label for the input field.
    ///   - placeholder: The placeholder text to display when the field is empty.
    ///   - text: A `Binding` to the string variable that will hold the input's value.
    ///   - errorMessage: An optional error message to display below the input field. If present, the border and label will turn red.
    ///   - isSecure: A Boolean value indicating whether the text input should obscure the text for secure entry, such as passwords.
    public init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        errorMessage: String? = nil,
        isSecure: Bool = false
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.errorMessage = errorMessage
        self.isSecure = isSecure
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(errorMessage == nil ? Assets.theme.secondaryText : .red)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(Assets.theme.secondaryText))
                    .padding()
                    .background(Assets.theme.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                        // Highlight border in red if there is an error
                            .stroke(errorMessage == nil ? Color.white.opacity(0.1) : Color.red, lineWidth: 1)
                    )
                    .foregroundColor(.white)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Assets.theme.secondaryText))
                    .padding()
                    .background(Assets.theme.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                        // Highlight border in red if there is an error
                            .stroke(errorMessage == nil ? Color.white.opacity(0.1) : Color.red, lineWidth: 1)
                    )
                    .foregroundColor(.white)
            }
            
            // Display the error message if it exists
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .transition(.opacity) // Smooth appearance
            }
        }
        .animation(.default, value: errorMessage)
    }
}
