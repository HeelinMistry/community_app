//
//  URLRequestExtension.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/04/28.
//

import Foundation

extension URLRequest {
    /// Generates a cURL command string representation of the URLRequest.
    ///
    /// This property constructs a cURL command that can be used to replicate the
    /// network request from the command line. It includes the HTTP method,
    /// headers, and HTTP body if present.
    public nonisolated var curlCommand: String? {
        guard let url = url else { return nil }
        var components = ["curl -v -X \(httpMethod ?? "GET")"]
        
        if let headers = allHTTPHeaderFields {
            for (field, value) in headers {
                components.append("-H '\(field): \(value)'")
            }
        }
        
        if let httpBody = httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            // Escape single quotes in the body string for cURL compatibility
            let escapedBodyString = bodyString.replacingOccurrences(of: "'", with: "'\\''")
            components.append("-d '\(escapedBodyString)'")
        }
        
        // Escape single quotes in the URL string for cURL compatibility
        let escapedURLString = url.absoluteString.replacingOccurrences(of: "'", with: "'\\''")
        components.append("'\(escapedURLString)'")
        return components.joined(separator: " ")
    }
}
