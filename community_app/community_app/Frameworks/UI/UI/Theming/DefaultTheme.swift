//
//  DefaultTheme.swift
//  UI
//
//  Created by Heelin Mistry on 2026/04/26.
//

import SwiftUI

/// A default implementation of the `Theme` protocol, providing a basic color scheme.
/// Colors are loaded from asset catalogs within the UI framework's bundle or system colors.
public struct DefaultTheme: Theme {
    public init() {}
    
    // Brand Colors
    public var primary: Color { Color("BrandLime", bundle: Bundle(for: UIBundleLocator.self)) }
    public var secondary: Color { Color("BrandDarkGray", bundle: Bundle(for: UIBundleLocator.self)) }
    public var tertiary: Color { Color("BrandLightBlue", bundle: Bundle(for: UIBundleLocator.self)) }
    public var neutral: Color { Color(.white) }
    
    // Functional Surface Colors
    /// Maps the primary accent color to the `primary` brand color.
    public var primaryAccent: Color { primary }
    /// The background color for input fields, loaded from "InputBg" in the bundle.
    public var inputBackground: Color { Color("InputBg", bundle: Bundle(for: UIBundleLocator.self)) }
    /// The background color for general surfaces, mapped to the `secondary` brand color.
    public var surfaceBackground: Color { Color("DarkGray", bundle: Bundle(for: UIBundleLocator.self)) }
    
    // Text Colors
    /// The primary text color, loaded from "Black" in the bundle.
    public var primaryText: Color { Color("BrandBlack", bundle: Bundle(for: UIBundleLocator.self)) }
    /// The secondary text color, derived from the `neutral` color with 80% opacity.
    public var secondaryText: Color { neutral.opacity(0.8) }
}
