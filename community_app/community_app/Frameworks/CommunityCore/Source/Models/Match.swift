//
//  Match.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

public nonisolated struct MatchResponse: Sendable, Equatable, Encodable, Decodable {
    public let success: Bool
    public let id: String

    public init(success: Bool, id: String) {
        self.success = success
        self.id = id
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        success = try values.decode(Bool.self, forKey: .success)
        id = try values.decode(String.self, forKey: .id)
    }
}
