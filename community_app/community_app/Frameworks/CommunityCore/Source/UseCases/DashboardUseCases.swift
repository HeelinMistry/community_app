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

public final class MatchUseCases: MatchUseCaseProtocol {
    
    private let match: any MatchRepositoryProtocol

    public init(match: any MatchRepositoryProtocol) {
        self.match = match
    }

    public func userRelatedMatches() async throws -> Matches {
        do {
            let matchResponse = try await match.getMatches()
            return (matchResponse)
        } catch {
            throw error
        }
    }
    
    public func userCreateMatch(_ request: CreateMatchRequest) async throws -> CreateMatchResponse {
        do {
            let matchResponse = try await match.createMatch(request)
            return (matchResponse)
        } catch {
            throw error
        }
    }
    
}
