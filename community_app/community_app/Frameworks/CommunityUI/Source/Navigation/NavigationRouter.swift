//
//  NavigationRouter.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/28.
//

import SwiftUI
import Combine

public enum Destination: Hashable {
    case login
    case dashboard
}

public enum SheetDestination: Identifiable {
    case registration
    case createMatch
    
    public var id: String { String(describing: self) }
}

@MainActor
public class NavigationRouter: ObservableObject {
    // For Stack Navigation
    @Published public var path = NavigationPath()
    
    // For Sheets and Modals
    @Published public var sheet: SheetDestination?
    
    // For Alerts
    @Published public var alertItem: AlertItem?
    
    @Published public var isAuthenticated: Bool = false
    
    public init() {}
    
    public func navigate(to destination: Destination) {
        path.append(destination)
    }
    
    public func present(sheet: SheetDestination) {
        self.sheet = sheet
    }
    
    public func alert(title: String, message: String) {
        self.alertItem = AlertItem(title: title, message: message, dismissButton: .default(Text("OK")))
    }
    
    public func loginSuccess() {
        self.sheet = nil // Close the registration/login sheet
        self.isAuthenticated = true
        self.path = NavigationPath() // Clear stack for a fresh start
    }
}

/// A structure to manage alerts across the app.
public struct AlertItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let dismissButton: Alert.Button
}
