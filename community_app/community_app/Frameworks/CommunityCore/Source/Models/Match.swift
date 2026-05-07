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
    public let date: String
    public let time: String
    public let location: String
    public let roster_size: Int
    public let cost: String
    public let is_host: Bool
    public let is_cancelled: Bool
    
    public init(
        match_id: String = "m_8c45a00e",
        title: String = "Untitled Match",
        date_event: String = "2000-01-01",
        time: String = "00:00",
        location: String = "Undisclosed Location",
        roster_size: Int = 0,
        cost: String = "0.00",
        is_host: Bool = false,
        is_cancelled: Bool = false
    ) {
        self.match_id = match_id
        self.title = title
        self.date = date_event
        self.time = time
        self.location = location
        self.roster_size = roster_size
        self.cost = cost
        self.is_host = is_host
        self.is_cancelled = is_cancelled
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        match_id = try values.decode(String.self, forKey: .match_id)
        title = try values.decode(String.self, forKey: .title)
        date = try values.decode(String.self, forKey: .date)
        time = try values.decode(String.self, forKey: .time)
        location = try values.decode(String.self, forKey: .location)
        roster_size = try values.decode(Int.self, forKey: .roster_size)
        cost = try values.decode(String.self, forKey: .cost)
        is_host = try values.decode(Bool.self, forKey: .is_host)
        is_cancelled = try values.decode(Bool.self, forKey: .is_cancelled)
    }
}

public nonisolated struct CreateMatchRequest: Sendable, Equatable, Encodable, Decodable {
    public let title: String
    public let sport: String
    public let duration: String
    public let date_event: String
    public let time: String
    public let location: String
    public let roster_size: String
    public let cost: String
    
    public init(
        title: String = "New Match",
        sport: String = "Soccer",
        duration: String = "60",
        date_event: String = "2000-01-01",
        time: String = "12:00",
        location: String = "Local Park",
        roster_size: String = "10",
        cost: String = "50"
    ) {
        self.title = title
        self.sport = sport
        self.duration = duration
        self.date_event = date_event
        self.time = time
        self.location = location
        self.roster_size = roster_size
        self.cost = cost
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        sport = try values.decode(String.self, forKey: .sport)
        duration = try values.decode(String.self, forKey: .duration)
        date_event = try values.decode(String.self, forKey: .date_event)
        time = try values.decode(String.self, forKey: .time)
        location = try values.decode(String.self, forKey: .location)
        roster_size = try values.decode(String.self, forKey: .roster_size)
        cost = try values.decode(String.self, forKey: .cost)
    }
}

public nonisolated struct CreateMatchResponse: Sendable, Equatable, Encodable, Decodable {
    public let match_id: String
    
    public init(match_id: String) {
        self.match_id = match_id
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        match_id = try values.decode(String.self, forKey: .match_id)
    }
}
