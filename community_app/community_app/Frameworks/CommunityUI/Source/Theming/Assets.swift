//
//  CommunityTheme.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/25.
//

import SwiftUI

private class BundleLocator {}

/// A collection of static assets and theming capabilities for the community application.
///
/// This enum provides access to the application's current theme and a helper for loading images.
public enum Assets {
    /// The currently active theme for the application.
    ///
    /// This theme can be swapped at runtime to change the appearance of the app.
    public static var theme: Theme = DefaultTheme()
    
    /// Loads an image from the asset catalog.
    /// - Parameter name: The name of the image asset.
    /// - Returns: An `Image` view corresponding to the specified asset name.
    public static func image(_ name: String) -> Image {
        Image(name, bundle: Bundle(for: UIBundleLocator.self))
    }
}
