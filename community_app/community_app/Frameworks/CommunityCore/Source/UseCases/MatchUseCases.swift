//
//  DashboardUseCase.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/30.
//

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
    
    public func matchDetail(_ request: MatchDetailRequest) async throws -> MatchDetailResponse {
        do {
            let matchDetailResponse = try await match.getMatch(request)
            return (matchDetailResponse)
        } catch {
            throw error
        }
    }
    
    public func toggleParticipation(_ request: MatchDetailRequest) async throws -> ParticipationResponse {
        do {
            let participationResponse = try await match.toggleParticipation(request)
            return (participationResponse)
        } catch {
            throw error
        }
    }
    
    public func toggleCancellation(_ request: MatchDetailRequest) async throws -> CancellationResponse {
        do {
            let participationResponse = try await match.toggleMatch(request)
            return (participationResponse)
        } catch {
            throw error
        }
    }
    
}
