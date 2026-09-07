//
//  DetailRequest.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/28.
//

import Foundation

public struct DetailRequest: Codable, Equatable, Hashable, Sendable {
    public let id: String

    public init(_ id: String) {
        self.id = id
    }
}
