//
//  MatchDetail.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/14.
//

import Foundation

public nonisolated struct MatchDetailRequest: Sendable, Equatable, Encodable, Decodable {
    public let match_id: String
    
    public init(_ match_id: String) {
        self.match_id = match_id
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        match_id = try values.decode(String.self, forKey: .match_id)
    }
}

public nonisolated struct MatchDetailResponse: Sendable, Equatable, Encodable, Decodable {
    public let title: String
    public let sport: String
    public let duration: String
    public let start_datetime: String
    public let location: String
    public let latitude: Double
    public let longitude: Double
    public let roster_size: Int
    public let cost: String
    public let is_host: Bool
    public var current_roster: Int
    public var player_list: [String]
    public var is_cancelled: Bool
    public var is_joined: Bool
    
    public init(
        title: String = "New Match",
        sport: String = "Soccer",
        duration: String = "60",
        start_datetime: String = "2000-01-01",
        location: String = "Local Park",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        roster_size: Int = 10,
        cost: String = "50",
        is_host: Bool = false,
        current_roster: Int = 0,
        player_list: [String] = ["test_user"],
        is_cancelled: Bool = false,
        is_joined: Bool = false
    ) {
        self.title = title
        self.sport = sport
        self.duration = duration
        self.start_datetime = start_datetime
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.roster_size = roster_size
        self.cost = cost
        self.is_host = is_host
        self.current_roster = current_roster
        self.player_list = player_list
        self.is_cancelled = is_cancelled
        self.is_joined = is_joined
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        sport = try values.decode(String.self, forKey: .sport)
        duration = try values.decode(String.self, forKey: .duration)
        start_datetime = try values.decode(String.self, forKey: .start_datetime)
        location = try values.decode(String.self, forKey: .location)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
        roster_size = try values.decode(Int.self, forKey: .roster_size)
        cost = try values.decode(String.self, forKey: .cost)
        is_host = try values.decode(Bool.self, forKey: .is_host)
        current_roster = try values.decode(Int.self, forKey: .current_roster)
        player_list = try values.decode([String].self, forKey: .player_list)
        is_cancelled = try values.decode(Bool.self, forKey: .is_cancelled)
        is_joined = try values.decode(Bool.self, forKey: .is_joined)
    }
}
