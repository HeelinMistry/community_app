//
//  AuthSessionManager.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/01.
//

protocol TokenProvider {
    func getAccessToken() -> String?
}

import Foundation
import CommunityCore

/// A thread-safe manager to handle the user's authentication session.
public actor AuthSessionManager {
    /// The shared singleton instance of the authentication session manager.
    public nonisolated static let shared = AuthSessionManager()
    
    private let tokenKey = "com.community.access_token"
    
    private init() {}
    
    /// Saves the session data after a successful login.
    public func saveSession(response: LoginResponse) {
        UserDefaults.standard.set(response.access_token, forKey: tokenKey)
    }
    
    /// Retrieves the current token for API requests.
    public func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    /// Clears the session (Logout).
    public func clearSession() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    /// Indicates whether a user is currently authenticated.
    public var isAuthenticated: Bool {
        getToken() != nil
    }
}
