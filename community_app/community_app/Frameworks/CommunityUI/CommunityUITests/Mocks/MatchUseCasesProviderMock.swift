//
//  MatchUseCasesProviderMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class MatchUseCasesMock: MatchUseCaseProtocol, @unchecked Sendable {

    var matchResult: Result<Matches, Error>?
    func userRelatedMatches() async throws -> Matches {
        if let result = matchResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
    var createMatchResult: Result<CreateMatchResponse, Error>?
    func userCreateMatch(_ request: CreateMatchRequest) async throws -> CreateMatchResponse {
        if let result = createMatchResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
    var matchDetailsResult: Result<MatchDetailResponse, Error>?
    func matchDetail(_ request: MatchDetailRequest) async throws -> MatchDetailResponse {
        if let result = matchDetailsResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
    var participationResult: Result<ParticipationResponse, Error>?
    func toggleParticipation(_ matchRequest: MatchDetailRequest) async throws -> ParticipationResponse {
        if let result = participationResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
    var cancellationResult: Result<CancellationResponse, Error>?
    func toggleCancellation(_ matchRequest: MatchDetailRequest) async throws -> CancellationResponse {
        if let result = cancellationResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in MatchUseCaseProtocol")
    }
    
}

final class NotificationMock: NotificationProtocol, @unchecked Sendable {
    var authorizationRequested = false
    var scheduledMatchID: String?
    var cancelledMatchID: String?
    
    var shouldThrowError = false
    
    public func requestAuthorization() async throws {
        if shouldThrowError { throw NotificationError.denied }
        authorizationRequested = true
    }
    
    public func scheduleMatchNotification(
        id: String,
        title: String,
        location: String,
        startDate: Date
    ) async throws -> (scheduledDate: Date, message: String) {
        if shouldThrowError { throw NotificationError.pastDate }
        self.scheduledMatchID = id
        return (startDate, "Scheduled")
    }
    
    public func cancelMatchNotification(id: String) {
        self.cancelledMatchID = id
    }
}

// Mock for the provider that holds the use case
final class MatchUseCasesProviderMock: MatchDetailUseCasesProvider, @unchecked Sendable {
    let mockMatchUseCases = MatchUseCasesMock()
    let notificationMock = NotificationMock()
    var matches: any MatchUseCaseProtocol { mockMatchUseCases }
    var notifications: any NotificationProtocol { notificationMock }
}
