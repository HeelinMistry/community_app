//
//  PrimaryButton.swift
//  UI
//
//  Created by Heelin Mistry on 2026/04/25.
//

import SwiftUI

/// A prominent, primary call-to-action button styled with a "Lime" background and black text.
/// It automatically uppercases its title and expands to fill available horizontal space.
public struct PrimaryButton: View {
    /// The text displayed on the button. It will be uppercased automatically.
    let title: String
    /// The action to perform when the button is tapped.
    let action: () -> Void
    
    /// Creates a primary button with a given title and action.
    /// - Parameters:
    ///   - title: The string to display on the button.
    ///   - action: A closure to execute when the button is pressed.
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Assets.theme.primaryAccent)
                .cornerRadius(14)
        }
    }
}
