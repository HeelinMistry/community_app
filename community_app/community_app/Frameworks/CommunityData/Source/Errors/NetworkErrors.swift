//
//  Errors.swift
//  Data
//
//  Created by Heelin Mistry on 2026/02/20.
//

import Foundation

public enum NetworkError: Error, LocalizedError, Equatable { 
    case invalidURL
    case serverError(Int)
    case decodingFailed
    case noData
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "The URL provided was invalid."
        case .serverError(let code): return "Server returned an error: \(code)."
        case .decodingFailed: return "Failed to parse the weather data."
        case .noData: return "No data was returned from the server."
        case .unknown(let error): return error.localizedDescription
        }
    }
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.decodingFailed, .decodingFailed):
            return true
        case (.noData, .noData):
            return true
        // For unknown errors, compare their localized descriptions for equality.
        // This might not be perfectly robust for all error types but provides a reasonable default.
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
