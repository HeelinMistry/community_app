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
    case matchDetail(match_id: String)
    case supplierDetail(supplier_id: String) 
    case productDetail(product_id: String) 
}

public enum SheetDestination: Identifiable {
    case registration
    case createMatch
    case createSupplier
    case advertiseProduct
    
    public var id: String { String(describing: self) }
}

public enum PendingType: String {
    case match
    case supplier
    case product
    
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
    @Published public var pendingID: String?
    @Published public var pendingType: PendingType?
    
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
        self.sheet = nil 
        self.isAuthenticated = true
        self.path = NavigationPath()
        
        if let ID = pendingID,
           let type = pendingType {
            pendingID = nil
            pendingType = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch type {
                case .match:
                    self.navigate(to: .matchDetail(match_id: ID))
                case .product:
                    self.navigate(to: .productDetail(product_id: ID))
                case .supplier:
                    self.navigate(to: .supplierDetail(supplier_id: ID))
                }
            }
        }
    }
    
    public func handleDeepLink(type: String, id: String) {
        print("handleDeepLink called with type: \(type), ID: \(id)")
        pendingType = PendingType(rawValue: type)
        
        if !isAuthenticated {
            pendingID = id
            alert(title: "Log in required", message: "Please log in to continue.")
            print("User is not authenticated, deep link navigation skipped.")
            return
        }
        
        print("User is authenticated, navigating for type: \(type)")
        switch pendingType {
        case .match:
            navigate(to: .matchDetail(match_id: id))
        case .supplier:
            navigate(to: .supplierDetail(supplier_id: id))
        case .product:
            navigate(to: .productDetail(product_id: id))
        case nil:
            print("Unsupported deep link type: \(type)")
        }
    }
}

/// A structure to manage alerts across the app.
public struct AlertItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let dismissButton: Alert.Button
}
