//
//  PrimaryText.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/01.
//

import SwiftUI

/// A primary text input field with a label and a placeholder, designed for user data entry.
/// It features a distinct background and border styling.
public struct PrimaryText: View {
    /// The label text displayed above the input field, typically uppercased and gray.
    let label: String
    
    /// Creates a primary text input field.
    /// - Parameters:
    ///   - label: The label for the input field.
    public init(
        label: String
    ) {
        self.label = label
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.secondaryText)
        }
    }
}
