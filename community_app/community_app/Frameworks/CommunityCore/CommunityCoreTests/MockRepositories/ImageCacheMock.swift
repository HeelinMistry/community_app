//
//  ImageCacheMock.swift
//  CommunityCoreTests
//
//  Created by Heelin Mistry on 2026/09/19.
//

import Foundation
import CommunityCore

public actor ImageCacheMock: ImageCacheProtocol {

    var cachedImageURLResult: Result<URL, Error>?

    func setCachedImageURLResult(_ result: Result<URL, Error>) {
        cachedImageURLResult = result
    }

    public func getCachedImageURL(for remotePath: String) async throws -> URL {
        guard let cachedImageURLResult else {
            fatalError("Result not set in ImageCacheMock")
        }

        return try cachedImageURLResult.get()
    }
}
