//
//  BrandLogo.swift
//  UI
//
//  Created by Heelin Mistry on 2026/04/25.
//

import SwiftUI

/// A custom `View` that displays a brand logo with two distinct string components,
/// styled with specific colors, font, and italics.
public struct BrandLogo: View {
    /// The primary string component of the logo, displayed in white.
    let primaryString: String
    /// The secondary string component of the logo, displayed in a "Lime" color.
    let secondaryString: String
    
    /// Creates a brand logo view with a primary and secondary string.
    /// - Parameters:
    ///   - primaryString: The main string for the logo, typically representing the first part of a brand name.
    ///   - secondaryString: The complementary string for the logo, typically representing the second part.
    public init(_ primaryString: String, secondaryString: String) {
        self.primaryString = primaryString
        self.secondaryString = secondaryString
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            Text(primaryString)
                .foregroundColor(Assets.theme.secondaryText)
            Text(secondaryString)
                .foregroundColor(Assets.theme.primaryAccent)
        }
        .font(.system(size: 42, weight: .black, design: .default))
        .italic()
        .padding(.top, 20)
    }
}
