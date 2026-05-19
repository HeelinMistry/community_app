//
//  Participation.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/05/15.
//

public nonisolated struct ParticipationResponse: Sendable, Equatable, Encodable, Decodable {
    public let status: String
    public let current_roster: Int
    public let is_joined: Bool
    public let player_list: [String]
    
    public init(
        status: String = "success",
        current_roster: Int = 0,
        is_joined: Bool = false,
        player_list: [String] = ["Test User"]
    ) {
        self.status = status
        self.current_roster = current_roster
        self.is_joined = is_joined
        self.player_list = player_list
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
        current_roster = try values.decode(Int.self, forKey: .current_roster)
        is_joined = try values.decode(Bool.self, forKey: .is_joined)
        player_list = try values.decode([String].self, forKey: .player_list)
    }
}
