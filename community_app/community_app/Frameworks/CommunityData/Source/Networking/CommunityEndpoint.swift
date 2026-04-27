//
//  CommunityEndpoint.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import CommunityCore

/// A protocol defining the basic requirements for an API endpoint.
public protocol APIEndpoint: Sendable {
    /// The base URL for the API endpoint.
    nonisolated var baseURL: URL { get }
    /// The specific path component for the API endpoint.
    nonisolated var path: String { get }
    /// The HTTP method to be used for the request (e.g., GET, POST).
    nonisolated var method: HTTPMethod { get }
    /// An array of URL query items to be appended to the URL.
    nonisolated var queryItems: [URLQueryItem] { get }
    /// A body for a endpoint
    nonisolated var body: (any Encodable & Sendable)? { get }
}

/// An enumeration defining standard HTTP methods.
public enum HTTPMethod: String, Sendable {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
}

/// An enumeration representing specific endpoints for the OpenWeatherMap API.
enum CommunityEndpoint: APIEndpoint {
    /// Represents the current weather endpoint.
    /// - Parameters:
    ///   - lat: The latitude for the location.
    ///   - lon: The longitude for the location.
    case login(loginRequest: LoginRequest)
    
    /// The base URL for the OpenWeatherMap API.
    var baseURL: URL { URL(string: "http://localhost:8000/")! }
    
    /// The HTTP method for all OpenWeatherMap endpoints, which is GET.
    var method: HTTPMethod {
        return .post
    }
    
    /// The specific path for each OpenWeatherMap endpoint.
    var path: String {
        switch self {
        case .login: return "api/v1/auth/login"
        }
    }
    
    /// The query items required for each endpoint
    var queryItems: [URLQueryItem] {
        switch self {
        case .login:
            return []
        }
    }
    
    /// The body required for each endpoint
    var body: (Encodable & Sendable)? {
        switch self {
        case .login(let loginRequest):
            return loginRequest
        }
    }
}

extension APIEndpoint {
    /// Constructs a `URLRequest` based on the endpoint's properties.
    ///
    /// This computed property combines the `baseURL`, `path`, `queryItems`, and `method`
    /// to create a fully formed `URLRequest` ready for network communication.
    ///
    /// - Returns: An optional `URLRequest` if the URL can be constructed successfully, otherwise `nil`.
    public nonisolated var urlRequest: URLRequest? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        
        // Only attach query items if they aren't empty
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add JSON content type header for POST/PUT requests
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the body if it exists
        if let body = body {
            // Explicitly use the nonisolated initializer
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
