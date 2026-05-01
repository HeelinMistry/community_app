//
//  Login.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

public nonisolated struct LoginRequest: Sendable, Codable, Equatable {
    public let username: String
    public let password: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case password
    }
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        username = try values.decode(String.self, forKey: .username)
        password = try values.decode(String.self, forKey: .password)
    }
}

public nonisolated struct LoginResponse: Sendable, Equatable, Encodable, Decodable {
    public let access_token: String
    public let token_type: String
    public let display_name: String

    public init(access_token: String, token_type: String, display_name: String) {
        self.access_token = access_token
        self.token_type = token_type
        self.display_name = display_name
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        access_token = try values.decode(String.self, forKey: .access_token)
        token_type = try values.decode(String.self, forKey: .token_type)
        display_name = try values.decode(String.self, forKey: .display_name)
    }
}
