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
    /// A binding to the string value that the text field edits.
    @Binding var text: String
    
    /// Creates a primary text input field.
    /// - Parameters:
    ///   - label: The label for the input field.
    ///   - placeholder: The placeholder text to display when the field is empty.
    ///   - text: A `Binding` to the string variable that will hold the input's value.
    public init(label: String, placeholder: String, text: Binding<String>) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.secondaryText)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Assets.theme.secondaryText))
                .padding()
                .background(Assets.theme.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .foregroundColor(.white)
        }
    }
}
