//
//  ProductUseCasesProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/07/29.
//

import UIKit

public protocol ProductRepositoryProtocol: Sendable {

    func classify(_ images: [UIImage]) async throws -> (title: String, tags: [String])
    func create(_ product: AdvertiseProductRequest) async throws -> AdvertiseProductResponse
}

public protocol ProductUseCasesProtocol: Sendable {
    func classify(_ images: [UIImage]) async throws -> (title: String, tags: [String])
    func advertise(_ item: AdvertiseProductRequest) async throws -> AdvertiseProductResponse
}
