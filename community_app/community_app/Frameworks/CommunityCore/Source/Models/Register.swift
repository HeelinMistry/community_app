//
//  Register.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/29.
//

public nonisolated struct RegisterRequest: Sendable, Codable, Equatable {
    public let username: String
    public let displayName: String
    public let email: String
    public let cellNumber: String
    public let password: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case displayName
        case email
        case cellNumber
        case password
    }
    
    public init(username: String, displayName: String, email: String, cellNumber: String, password: String) {
        self.username = username
        self.displayName = displayName
        self.email = email
        self.cellNumber = cellNumber
        self.password = password
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        username = try values.decode(String.self, forKey: .username)
        displayName = try values.decode(String.self, forKey: .displayName)
        email = try values.decode(String.self, forKey: .email)
        cellNumber = try values.decode(String.self, forKey: .cellNumber)
        password = try values.decode(String.self, forKey: .password)
    }
}

public nonisolated struct RegisterResponse: Sendable, Equatable, Encodable, Decodable {
    public let success: Bool
    public let message: String

    public init(success: Bool, message: String) {
        self.success = success
        self.message = message
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        success = try values.decode(Bool.self, forKey: .success)
        message = try values.decode(String.self, forKey: .message)
    }
}
