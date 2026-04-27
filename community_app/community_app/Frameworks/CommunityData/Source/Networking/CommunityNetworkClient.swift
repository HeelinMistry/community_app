//
//  CommunityNetworkClient.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import os

/// A network client for making API requests to an auth service.
///
/// This actor provides a generic `fetch` method to handle API requests,
/// decode the responses, and manage network-related errors.
public actor CommunityNetworkClient {
    private let session: URLSession
//    private let logger = Logger(subsystem: "com.community.app", category: "Networking")
    
    /// Initializes a new `CommunityNetworkClient` instance.
    /// - Parameter session: The `URLSession` to use for network requests. Defaults to `URLSession.shared`.
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetch<T: Decodable>(from endpoint: APIEndpoint) async throws -> T {
        guard let request = endpoint.urlRequest else {
            print("Invalid URL for path: \(endpoint.path)")
//            Log.networking.fault("Invalid URL for path: \(endpoint.path)")
            throw NetworkError.invalidURL
        }
        
        let method = endpoint.method.rawValue
        print(method)
//        Log.networking.debug("\(method) Requesting: \(endpoint.redactedURLString)")
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            // This case should ideally not happen with URLSession.data(for:), as it typically returns HTTPURLResponse for http/https.
            // A status code of 0 is used to indicate an unknown server error when the response type is unexpected.
            print("Invalid response: \(response)")
            throw NetworkError.serverError(0)
        }
        if !(200...299).contains(httpResponse.statusCode) {
//            Log.networking.error("Status Code: \(httpResponse.statusCode) for \(endpoint.path)")
            print("Invalid response: \(httpResponse.statusCode)")
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        do {
            print(response)
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(T.self, from: data)
//            Log.networking.info("Successfully decoded \(T.self)")
            return decodedData
        } catch {
            print("NetworkError decodingFailed")
//            Log.networking.error("Decoding failed for \(T.self): \(error.localizedDescription)")
            throw NetworkError.decodingFailed
        }
    }
}
