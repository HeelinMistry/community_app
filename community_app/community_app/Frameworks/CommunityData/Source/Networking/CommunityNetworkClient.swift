//
//  CommunityNetworkClient.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/04/27.
//

import Foundation
import os
import UIKit

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
        guard var request = endpoint.createRequest(relativeTo: networkConfig.baseURL) else {
            logger.logError(NetworkError.invalidURL, for: endpoint.path)
            throw NetworkError.invalidURL
        }
        if let token: String = await AuthSessionManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        logger.logRequest(request)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(0)
        }
        logger.logResponse(httpResponse, data: data)
        
        if (400...499).contains(httpResponse.statusCode) {
            if let errorBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw NetworkError.customError(errorBody.detail)
            } else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        }
        
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
    
    /// Uploads multiple images to a specific endpoint using multipart/form-data.
    public func upload<T: Decodable>(to endpoint: APIEndpoint, images: [UIImage], fileParameterName: String = "files") async throws -> T {
        guard let url = URL(string: endpoint.path, relativeTo: networkConfig.baseURL) else {
            logger.logError(NetworkError.invalidURL, for: endpoint.path)
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Retrieve and set authorization token if available
        if let token: String = await AuthSessionManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        for (index, image) in images.enumerated() {
            // Optimize/compress image data using your preprocessor helper
            // FIX: Call optimizeForUpload on the MainActor
            let optionalImageData: Data? = await MainActor.run {
                ImagePreprocessor.optimizeForUpload(image)
            }
            guard let imageData = optionalImageData else { continue }
            
            body.append(Data("\r\n--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(fileParameterName)\"; filename=\"product_\(index).jpg\"\r\n".utf8))
            body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
            body.append(imageData)
        }
        
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        request.httpBody = body
        
        logger.logRequest(request)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(0)
        }
        
        logger.logResponse(httpResponse, data: data)
        
        if (400...499).contains(httpResponse.statusCode) {
            if let errorBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw NetworkError.customError(errorBody.detail)
            } else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.logError(error, for: request.url?.absoluteString ?? endpoint.path)
            throw NetworkError.decodingFailed
        }
    }
    
    /// Generates a fully qualified URL for a given image path relative to the base URL.
    public func image(path: String) -> URL {
        
        // Resolves leading-slash paths correctly against the base URL host
        if let resolvedURL = URL(string: "/static/uploads/\(path)", relativeTo: networkConfig.baseURL) {
            return resolvedURL
        }
        return URL(string: path)!
    }
}
