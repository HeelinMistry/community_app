//
//  CommunityTheme.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/25.
//

import SwiftUI

private class BundleLocator {}

public enum Assets {
    // Current theme - can be swapped at runtime
    public static var theme: Theme = DefaultTheme()
    
    // Helper for images
    public static func image(_ name: String) -> Image {
        Image(name, bundle: Bundle(for: UIBundleLocator.self))
    }
}
