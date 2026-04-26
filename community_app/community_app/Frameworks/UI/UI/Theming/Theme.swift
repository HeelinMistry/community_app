//
//  Theme.swift
//  UI
//
//  Created by Heelin Mistry on 2026/04/25.
//

import SwiftUI

/// A public class to help locate the bundle of the UI framework.
/// This is used for loading assets, such as colors, specific to the UI framework's bundle.
public class UIBundleLocator {}

/// A protocol defining the color palette for the application's user interface.
/// Conforming to this protocol allows for consistent theming across different UI components.
public protocol Theme {
    // Brand Colors
    
    /// The primary brand color.
    var primary: Color { get }
    /// The secondary brand color, often used as an accent or complementary shade.
    var secondary: Color { get }
    /// The tertiary brand color, providing further depth or distinction to the palette.
    var tertiary: Color { get }
    /// A neutral color, typically used for backgrounds or subtle UI elements.
    var neutral: Color { get }
    
    // Functional Surface Colors
    
    /// A primary accent color for interactive elements or highlights, often derived from the `primary` brand color.
    var primaryAccent: Color { get }
    /// The background color for input fields and similar interactive elements.
    var inputBackground: Color { get }
    /// The background color for general surfaces and containers within the UI.
    var surfaceBackground: Color { get }
    
    // Text Colors
    
    /// The primary text color, used for main headings and body text.
    var primaryText: Color { get }
    /// The secondary text color, often used for less prominent text like subheadings or captions.
    var secondaryText: Color { get }
}
