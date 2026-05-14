//
//  Match.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation

/// A type alias for an array of `MatchResponse` objects.
public typealias Matches = [MatchResponse]

public nonisolated struct MatchResponse: Sendable, Equatable, Encodable, Decodable {
    public let match_id: String
    public let title: String
    public let start_datetime: String
    public let location: String
    public let roster_size: Int
    public let cost: String
    public let is_host: Bool
    public let is_cancelled: Bool
    public let is_joined: Bool
    public let joined: Int
    
    public init(
        match_id: String = "m_8c45a00e",
        title: String = "Untitled Match",
        start_datetime: String = "2026-05-07T18:00:00",
        location: String = "Undisclosed Location",
        roster_size: Int = 0,
        cost: String = "0.00",
        is_host: Bool = false,
        is_cancelled: Bool = false,
        is_joined: Bool = false,
        joined: Int = 0
    ) {
        self.match_id = match_id
        self.title = title
        self.start_datetime = start_datetime
        self.location = location
        self.roster_size = roster_size
        self.cost = cost
        self.is_host = is_host
        self.is_cancelled = is_cancelled
        self.is_joined = is_joined
        self.joined = joined
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        match_id = try values.decode(String.self, forKey: .match_id)
        title = try values.decode(String.self, forKey: .title)
        start_datetime = try values.decode(String.self, forKey: .start_datetime)
        location = try values.decode(String.self, forKey: .location)
        roster_size = try values.decode(Int.self, forKey: .roster_size)
        cost = try values.decode(String.self, forKey: .cost)
        is_host = try values.decode(Bool.self, forKey: .is_host)
        is_cancelled = try values.decode(Bool.self, forKey: .is_cancelled)
        is_joined = try values.decode(Bool.self, forKey: .is_joined)
        joined = try values.decode(Int.self, forKey: .joined)
    }
}
