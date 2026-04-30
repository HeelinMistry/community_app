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
    case login(_ loginRequest: LoginRequest)
    
    case register(_ registerRequest: RegisterRequest)
    
    /// The HTTP method for all OpenWeatherMap endpoints, which is GET.
    var method: HTTPMethod {
        return .post
    }
    
    /// The specific path for each OpenWeatherMap endpoint.
    var path: String {
        switch self {
        case .login: return "api/v1/auth/login"
        case .register: return "api/v1/auth/register"
        }
    }
    
    /// The query items required for each endpoint
    var queryItems: [URLQueryItem] {
        switch self {
        case .login,
                .register:
            return []
        }
    }
    
    /// The body required for each endpoint
    var body: (Encodable & Sendable)? {
        switch self {
        case .login(let loginRequest):
            return loginRequest
        case .register(let registerRequest):
            return registerRequest
        }
    }
}
