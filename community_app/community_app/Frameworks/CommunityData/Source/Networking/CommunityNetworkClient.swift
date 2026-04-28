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
    private let networkConfig: NetworkConfiguration
    private let logger: NetworkLogger
    
    /// Initializes a new `CommunityNetworkClient` instance.
    /// - Parameter session: The `URLSession` to use for network requests. Defaults to `URLSession.shared`.
    /// - Parameter networkConfig: The `NetworkConfiguration` to set base URL.
    public init(session: URLSession = .shared, networkConfig: NetworkConfiguration) {
        self.session = session
        self.networkConfig = networkConfig
        
        self.logger = .init(shouldLog: networkConfig.shouldLogSensitiveData)
    }
    
    func fetch<T: Decodable>(from endpoint: APIEndpoint) async throws -> T {
        guard let request = endpoint.createRequest(relativeTo: networkConfig.baseURL) else {
            logger.logError(NetworkError.invalidURL, for: endpoint.path)
            throw NetworkError.invalidURL
        }
        logger.logRequest(request)
            
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(0)
        }
        logger.logResponse(httpResponse, data: data)
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        do {
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(T.self, from: data)
            return decodedData
        } catch {
            logger.logError(error, for: request.url?.absoluteString ?? endpoint.path)
            throw NetworkError.decodingFailed
        }
    }
}
