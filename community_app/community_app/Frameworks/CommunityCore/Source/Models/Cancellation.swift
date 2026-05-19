//
//  Cancellation.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/05/18.
//

public nonisolated struct CancellationResponse: Sendable, Equatable, Encodable, Decodable {
    public let status: String
    public let is_cancelled: Bool
    
    public init(
        status: String = "success",
        is_cancelled: Bool = false
    ) {
        self.status = status
        self.is_cancelled = is_cancelled
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
        is_cancelled = try values.decode(Bool.self, forKey: .is_cancelled)
    }
}
