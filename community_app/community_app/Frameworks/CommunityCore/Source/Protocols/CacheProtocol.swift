//
//  CacheProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/09/07.
//

import Foundation

public protocol ImageCacheProtocol: Sendable {

    func getCachedImageURL(for remotePath: String) async throws -> URL 
}
