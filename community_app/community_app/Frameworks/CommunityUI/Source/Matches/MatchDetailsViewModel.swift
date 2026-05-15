//
//  MatchDetailsViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/14.
//

import Combine
import Foundation
import CommunityCore

@MainActor
public protocol MatchDetailsViewModelProtocol: StateDrivenViewModel where DataType == MatchDetailResponse {
    var matchDetailResponse: MatchDetailResponse? { get }
    var isTogglingParticipation: Bool { get } // Add published property to protocol
    func matchDetail()
    func toggle_match_participation()
}

@MainActor
public final class MatchDetailsViewModel: MatchDetailsViewModelProtocol {
    @Published public private(set) var state: ViewState<MatchDetailResponse> = .idle
    @Published public private(set) var isTogglingParticipation: Bool = false // New published property
    @Published public private(set) var matchDetailResponse: MatchDetailResponse?
    
    private let match_id: String
    
    private let router: NavigationRouter
    private let useCases: any MatchUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        useCases: any MatchUseCasesProvider,
        router: NavigationRouter,
        match_id: String
    ) {
        self.useCases = useCases
        self.router = router
        self.match_id = match_id
    }
    
    public func matchDetail() {
        if state == .loading {
            return
        }
        
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                let response: MatchDetailResponse = try await useCases.matches.matchDetail(.init(match_id))
                matchDetailResponse = response
                if !Task.isCancelled {
                    // Wrap the MatchDetailResponse in the enum case
                    if let matchDetailResponse {
                        self.state = .success(matchDetailResponse)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    public func toggle_match_participation() {
        guard !isTogglingParticipation else { return }
        
        // Use 'if var' to get a mutable copy of matchDetailResponse
        if var currentMatchDetail = self.matchDetailResponse {
            isTogglingParticipation = true
            fetchTask?.cancel() // Cancel any pending full refresh tasks
            
            // This task will specifically handle the participation toggle and in-place update
            fetchTask = Task {
                defer { isTogglingParticipation = false } 
                
                do {
                    let participationResponse: ParticipationResponse = try await useCases.matches.toggleParticipation(.init(match_id))
                    if !Task.isCancelled {
                        currentMatchDetail.is_joined = participationResponse.is_joined
                        currentMatchDetail.current_roster = participationResponse.current_roster
                        self.matchDetailResponse = currentMatchDetail
                        self.state = .success(currentMatchDetail)
                    }
                } catch {
                    if !Task.isCancelled {
                        self.state = .error(error.localizedDescription)
                    }
                }
            }
        }
    }
}
