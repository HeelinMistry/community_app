//
//  CreateMatch.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/14.
//

import Foundation

public nonisolated struct CreateMatchRequest: Sendable, Equatable, Encodable, Decodable {
    public let title: String
    public let sport: String
    public let duration: String
    public let start_datetime: String
    public let location: String
    public let latitude: Double
    public let longitude: Double
    public let roster_size: String
    public let cost: String
    
    public init(
        title: String = "New Match",
        sport: String = "Soccer",
        duration: String = "60",
        start_datetime: String = "2000-01-01",
        location: String = "Local Park",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        roster_size: String = "10",
        cost: String = "50"
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
