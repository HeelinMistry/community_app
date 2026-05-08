//
//  DashboardViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Combine
import Foundation
import CommunityCore

@MainActor
public protocol DashboardViewModelProtocol: StateDrivenViewModel where DataType == Matches, DataType: Collection, DataType.Element == MatchResponse {
    
    func matchFeed()
    func createMatchTapped()
}

@MainActor
public final class DashboardViewModel: DashboardViewModelProtocol {
    @Published public private(set) var state: ViewState<Matches> = .idle
    
    private let router: NavigationRouter
    private let useCases: any MatchUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    public init(
        useCases: any MatchUseCasesProvider,
        router: NavigationRouter
    ) {
        self.useCases = useCases
        self.router = router
    }
    
    public func matchFeed() {
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                let response: Matches = try await useCases.matches.userRelatedMatches()
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
    
    public func createMatchTapped() {
        router.sheet = .createMatch
    }
}
