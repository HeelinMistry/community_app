//
//  ViewFactory.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/28.
//

import SwiftUI

public protocol ViewFactory: Sendable {
    @MainActor func makeRegistrationView() -> AnyView
    @MainActor func makeLoginView() -> AnyView
}
