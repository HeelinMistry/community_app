//
//  Theme.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/25.
//

import SwiftUI
import UI


/// A community implementation of the `Theme` protocol, providing a custom color scheme.
/// Colors are loaded from asset catalogs within the Main app.
public struct CommunityTheme: Theme {
    public var primary: Color { Color("Pink", bundle: Bundle(for: UIBundleLocator.self)) }
    public var secondary: Color { Color("BrandDarkGray", bundle: Bundle(for: UIBundleLocator.self)) }
    public var tertiary: Color { Color("Light Blue", bundle: Bundle(for: UIBundleLocator.self)) }
    public var neutral: Color { Color(.white) }

    // Mapping functional colors to the palette
    public var primaryAccent: Color { primary }
    public var inputBackground: Color { Color("InputBg", bundle: Bundle(for: UIBundleLocator.self)) }
    public var surfaceBackground: Color { Color("DarkGray", bundle: Bundle(for: UIBundleLocator.self)) }
    
    public var primaryText: Color { Color("BrandBlack", bundle: Bundle(for: UIBundleLocator.self)) }
    public var secondaryText: Color { neutral.opacity(0.8) }
}

