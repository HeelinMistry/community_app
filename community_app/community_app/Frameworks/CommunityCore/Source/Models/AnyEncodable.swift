//
//  AnyEncodable.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

public struct AnyEncodable: Encodable, Sendable {
    private let _encode: @Sendable (Encoder) throws -> Void

    public nonisolated init(_ value: any Encodable & Sendable) {
        _encode = { try value.encode(to: $0) }
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
