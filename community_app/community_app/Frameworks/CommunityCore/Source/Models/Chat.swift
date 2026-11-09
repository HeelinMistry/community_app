//
//  Chat.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation

/// A type alias for an array of `ChatResponse` objects.
public typealias Chats = [ChatResponse]

public nonisolated struct ChatResponse: Sendable, Equatable, Encodable, Decodable {
    public let roomId: String
    public let title: String?
    public let lastContent: String?
    public let timestamp: String?
    
    public init(
        roomId: String,
        title: String? = nil,
        lastContent: String? = nil,
        timestamp: String? = nil
    ) {
        self.roomId = roomId
        self.title = title
        self.lastContent = lastContent
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.roomId = try container.decode(String.self, forKey: .roomId)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.lastContent = try container.decodeIfPresent(String.self, forKey: .lastContent)
        self.timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case title = "title"
        case lastContent = "last_content"
        case timestamp = "timestamp"
    }
}
