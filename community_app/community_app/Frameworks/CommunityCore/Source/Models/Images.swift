//
//  Images.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/10/16.
//

import Foundation

public enum Category: String, Codable, Equatable, Sendable {
    case products
    case reviews
}

public nonisolated struct ImagesRequest: Sendable, Codable, Equatable {
    public let requestId: String
    public let category: Category
    
    enum CodingKeys: String, CodingKey {
        case requestId
        case category
    }
    
    public init(requestId: String, category: Category) {
        self.requestId = requestId
        self.category = category
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        requestId = try values.decode(String.self, forKey: .requestId)
        category = try values.decode(Category.self, forKey: .category)
    }
}

public nonisolated struct ImagesResponse: Sendable, Codable, Equatable {
    public let images: [String]
    
    enum CodingKeys: String, CodingKey {
        case images
    }
    
    public init(images: [String]) {
        self.images = images
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        images = try values.decode([String].self, forKey: .images)
    }
}
