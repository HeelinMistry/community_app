//
//  DashboardRepository.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore

public final class DashboardRepository: DashboardRepositoryProtocol {
    
    private let networkClient: CommunityNetworkClient
    
    public init(networkClient: CommunityNetworkClient) {
        self.networkClient = networkClient
    }
    
    public func getMatches() async throws -> Matches {
        do {
            let dto: Matches = try await networkClient.fetch(from: CommunityEndpoint.matches)
            return dto
        } catch {
            throw error
        }
    }
}
