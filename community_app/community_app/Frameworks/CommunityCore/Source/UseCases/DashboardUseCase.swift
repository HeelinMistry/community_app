//
//  DashboardUseCase.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

/// This protocol is `Sendable` to ensure it can be safely used across concurrency domains.
public protocol DashboardUseCaseProtocol: Sendable {
    func getMatches() async throws -> MatchResponse

}

public final class DashboardUseCases: MatchUseCaseProtocol {
    
    private let dashboard: any DashboardRepositoryProtocol

    public init(dashboard: any DashboardRepositoryProtocol) {
        self.dashboard = dashboard
    }

    public func execute() async throws -> MatchResponse {
        do {
            let matchResponse = try await dashboard.getMatches()
            return (matchResponse)
        } catch {
            throw error
        }
    }
}
