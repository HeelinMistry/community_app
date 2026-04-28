//
//  NetworkLogger.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/04/28.
//

import Foundation
import os

public struct NetworkLogger: Sendable {
    private let logger = Logger(subsystem: "com.community.app", category: "Networking")
    let shouldLog: Bool

    public nonisolated func logRequest(_ request: URLRequest) {
        guard shouldLog else { return }
        
        let url = request.url?.absoluteString ?? "Unknown URL"
        let method = request.httpMethod ?? "UNKNOWN"
        
        logger.debug("🚀 \(method) \(url)")
        
        if let curl = request.curlCommand {
            logger.debug("💻 cURL: \(curl)")
        }
    }

    public nonisolated func logResponse(_ response: HTTPURLResponse, data: Data?) {
        guard shouldLog else { return }
        
        let icon = (200...299).contains(response.statusCode) ? "✅" : "❌"
        logger.info("\(icon) Status: \(response.statusCode) (\(response.url?.lastPathComponent ?? ""))")
        
        if let data = data, let json = String(data: data, encoding: .utf8) {
            logger.debug("📦 Body: \(json)")
        }
    }

    public nonisolated func logError(_ error: Error, for url: String) {
        logger.error("🚨 Error at \(url): \(error.localizedDescription)")
    }
}
