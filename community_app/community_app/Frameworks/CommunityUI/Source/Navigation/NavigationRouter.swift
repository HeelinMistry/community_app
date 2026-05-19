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
    case detail(match_id: String)
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
    @Published public var pendingMatchID: String?
    
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
        self.path = NavigationPath()
        
        if let matchID = pendingMatchID {
            self.pendingMatchID = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.navigate(to: .detail(match_id: matchID))
            }
        }
    }
    
    public func handleDeepLink(matchID: String) {
        print("handleDeepLink called with matchID: \(matchID)")
        if !isAuthenticated {
            pendingMatchID = matchID
            alert(title: "Log in required", message: "Please log in to view this match.")
            print("User is not authenticated, deep link navigation skipped.")
        }
        guard isAuthenticated else { return }
        print("User is authenticated, navigating to detail for matchID: \(matchID)")
        navigate(to: .detail(match_id: matchID))
    }
}

/// A structure to manage alerts across the app.
public struct AlertItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let dismissButton: Alert.Button
}
