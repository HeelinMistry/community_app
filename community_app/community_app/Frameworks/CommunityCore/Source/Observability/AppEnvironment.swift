//
//  AppEnvironment.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/28.
//

import Foundation

/// Defines the application's environment, determining configuration like API base URLs and logging behavior.
public enum AppEnvironment {
    /// Represents the development or debugging environment.
    case debug
    /// Represents the production or release environment.
    case release

    /// The base URL for API requests specific to the current environment.
    public var baseURL: URL {
        switch self {
        case .debug: return URL(string: "http://localhost:8000/")!
        case .release: return URL(string: "https://staging.api.community.com/")!
        }
    }

    /// A boolean indicating whether logging should be enabled for the current environment.
    public var shouldLog: Bool {
        switch self {
        case .debug: return true
        case .release: return false
        }
    }
}
