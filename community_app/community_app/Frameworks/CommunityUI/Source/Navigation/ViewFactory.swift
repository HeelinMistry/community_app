//
//  ViewFactory.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/28.
//

import SwiftUI

/// A protocol for a factory that creates various views within the application.
///
/// Types conforming to `ViewFactory` are responsible for instantiating specific UI components,
/// such as login and registration views, ensuring they are created on the main actor.
public protocol ViewFactory: Sendable {
    /// Creates and returns an `AnyView` for the registration flow.
    @MainActor func makeRegistrationView() -> AnyView
    /// Creates and returns an `AnyView` for the login flow.
    @MainActor func makeLoginView() -> AnyView
    /// Creates and returns an `AnyView` for the dashbaord flow.
    @MainActor func makeDashboardView() -> AnyView
    @MainActor func makeCreateMatchView() -> AnyView
    @MainActor func makeDetailMatchView(_ match_id: String) -> AnyView
}

private struct ViewFactoryKey: EnvironmentKey {
    static let defaultValue: any ViewFactory = DefaultViewFactory()
}

extension EnvironmentValues {
    /// An environment value that provides access to a `ViewFactory` instance.
    ///
    /// Use this property to retrieve the currently active `ViewFactory` for creating UI components.
    public var viewFactory: any ViewFactory {
        get { self[ViewFactoryKey.self] }
        set { self[ViewFactoryKey.self] = newValue }
    }
}

// Private fallback to satisfy the compiler
private struct DefaultViewFactory: ViewFactory {
    func makeLoginView() -> AnyView { AnyView(Text("Factory Missing")) }
    func makeRegistrationView() -> AnyView { AnyView(Text("Factory Missing")) }
    func makeDashboardView() -> AnyView { AnyView(Text("Factory Missing")) }
    func makeCreateMatchView() -> AnyView { AnyView(Text("Factory Missing")) }
    func makeDetailMatchView(_ match_id: String) -> AnyView { AnyView(Text("Factory Missing")) }
}
