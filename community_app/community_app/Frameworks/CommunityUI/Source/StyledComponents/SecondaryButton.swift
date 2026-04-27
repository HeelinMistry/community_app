//
//  SecondaryButton.swift
//  UI
//
//  Created by Heelin Mistry on 2026/04/25.
//

import SwiftUI

/// A secondary, less prominent button typically used for alternative actions or navigation,
/// styled with "Lime" colored text and no background.
public struct SecondaryButton: View {
    /// The text displayed on the button.
    let title: String
    /// The action to perform when the button is tapped.
    let action: () -> Void
    
    /// Creates a secondary button with a given title and action.
    /// - Parameters:
    ///   - title: The string to display on the button.
    ///   - action: A closure to execute when the button is pressed.
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.primaryAccent)
        }
    }
}
