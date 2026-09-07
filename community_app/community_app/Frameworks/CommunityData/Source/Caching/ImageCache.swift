//
//  ImageCache.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/09/07.
//

import CommunityCore
import Foundation
import UIKit

public actor ImageCache: ImageCacheProtocol {
    private let networkClient: CommunityNetworkClient
    private let fileManager = FileManager.default
    
    private lazy var cacheDirectory: URL = {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("ImageCache", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()
    
    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
    }
    
    /// Checks local cache for the image. If missing, downloads it, saves it locally, and returns the local file URL.
    public func getCachedImageURL(for remotePath: String) async throws -> URL {
        let localFileURL = cacheDirectory.appendingPathComponent(remotePath)
        
        // 1. Check if the image already exists locally on disk
        if fileManager.fileExists(atPath: localFileURL.path) {
            return localFileURL
        }
        
        // 2. If not cached, generate the remote download URL via your network client
        let remoteURL = await networkClient.image(path: remotePath)
        
        // 3. Unauthenticated get only for static images.
        let request = URLRequest(url: remoteURL)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // 4. Save the downloaded data to the local cache directory
        try data.write(to: localFileURL)
        return localFileURL
    }
}
