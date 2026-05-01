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
public protocol DashboardViewModelProtocol: StateDrivenViewModel {
    
    func matchFeed()
}

@MainActor
public final class DashboardViewModel: DashboardViewModelProtocol {
    @Published public private(set) var state: ViewState<MatchResponse> = .idle
    
    private let router: NavigationRouter
    private let useCases: any DashboardUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    public init(
        useCases: any DashboardUseCasesProvider,
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
                let response: MatchResponse = try await useCases.matches.execute()
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
}
