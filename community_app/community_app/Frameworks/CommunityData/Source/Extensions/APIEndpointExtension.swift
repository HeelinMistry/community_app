//
//  APIEndpointExtension.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/04/28.
//

import Foundation
import CommunityCore

extension APIEndpoint {
    /// Creates a `URLRequest` based on the endpoint's properties.
    /// - Parameter externalBaseURL: The base URL against which the endpoint's path should be resolved.
    /// - Returns: An optional `URLRequest` if the request can be successfully constructed, otherwise `nil`.
    public nonisolated func createRequest(relativeTo externalBaseURL: URL) -> URLRequest? {
        var components = URLComponents(url: externalBaseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let body = body {
            do {
                let encoder = JSONEncoder()
                let wrappedBody = AnyEncodable(body)
                request.httpBody = try encoder.encode(wrappedBody)
            } catch {
                print("Failed to encode body: \(error)")
                return nil
            }
        }
        
        return request
    }
}
