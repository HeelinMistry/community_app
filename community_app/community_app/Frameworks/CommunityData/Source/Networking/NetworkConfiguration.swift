//
//  NetworkConfiguration.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/28.
//

import Foundation

/// A configuration structure for network requests, defining base URL and logging behavior.
public struct NetworkConfiguration {
    /// The base URL for all network requests.
    public let baseURL: URL
    /// A boolean indicating whether sensitive data should be logged.
    public let shouldLogSensitiveData: Bool
    
    /// Initializes a new network configuration.
    /// - Parameters:
    ///   - baseURL: The base URL to use for all network requests.
    ///   - shouldLogSensitiveData: A boolean value indicating if sensitive data should be logged (e.g., for debugging purposes).
    public init(baseURL: URL, shouldLogSensitiveData: Bool) {
        self.baseURL = baseURL
        self.shouldLogSensitiveData = shouldLogSensitiveData
    }
}
