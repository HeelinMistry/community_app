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
    
    func matchDetail()
    func toggle_match_participation()
}

@MainActor
public final class MatchDetailsViewModel: MatchDetailsViewModelProtocol {
    @Published public private(set) var state: ViewState<MatchDetailResponse> = .idle
    
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
                if !Task.isCancelled {
                    self.state = .success(response)
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    public func toggle_match_participation() {
        
    }
}
