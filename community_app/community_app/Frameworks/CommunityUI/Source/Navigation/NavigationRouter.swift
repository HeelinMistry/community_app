//
//  NavigationRouter.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/28.
//

import SwiftUI
import Combine

/// Defines the possible navigation destinations.
public enum AppRoute: Identifiable {
    case registration
    case settings
    case profile
    
    public var id: String { String(describing: self) }
}

/// Manages the navigation state for the application.
@MainActor
public final class NavigationRouter: ObservableObject {
    @Published public var sheet: AppRoute?
    @Published public var fullScreenCover: AppRoute?
    @Published public var alertItem: AlertItem?

    public init() {}
    
    public func dismissSheet() { sheet = nil }
}

/// A structure to manage alerts across the app.
public struct AlertItem: Identifiable {
    public let id = UUID()
    public let title: Text
    public let message: Text
    public let dismissButton: Alert.Button
}
