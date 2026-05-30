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
    
    var upcomingMatches: [MatchResponse] { get }
    var historyMatches: [MatchResponse] { get }
    
    func matchFeed()
    func createMatchTapped()
}

@MainActor
public final class DashboardViewModel: DashboardViewModelProtocol {
    @Published public private(set) var state: ViewState<Matches> = .idle
    
    private let router: NavigationRouter
    private let useCases: any MatchUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
    
    public init(
        useCases: any MatchUseCasesProvider,
        router: NavigationRouter
    ) {
        self.useCases = useCases
        self.router = router
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .matchCreated)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.matchFeed()
            }
            .store(in: &cancellables)
    }
    
    public func matchFeed() {
        if state == .loading {
            return
        }
        
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
    
    // MARK: - Match Filtering
    
    public var upcomingMatches: [MatchResponse] {
        guard case .success(let matches) = state else { return [] }
        let now = Date()
        return matches.filter { match in
            guard let matchDate = DashboardViewModel.isoDateFormatter.date(from: match.start_datetime) else { return false }
            return matchDate > now
        }.sorted(by: {
            guard let date1 = DashboardViewModel.isoDateFormatter.date(from: $0.start_datetime),
                  let date2 = DashboardViewModel.isoDateFormatter.date(from: $1.start_datetime) else { return false }
            return date1 < date2 // Sort upcoming from earliest to latest
        })
    }
    
    public var historyMatches: [MatchResponse] {
        guard case .success(let matches) = state else { return [] }
        let now = Date()
        return matches.filter { match in
            guard let matchDate = DashboardViewModel.isoDateFormatter.date(from: match.start_datetime) else { return false }
            return matchDate <= now
        }.sorted(by: {
            guard let date1 = DashboardViewModel.isoDateFormatter.date(from: $0.start_datetime),
                  let date2 = DashboardViewModel.isoDateFormatter.date(from: $1.start_datetime) else { return false }
            return date1 > date2 // Sort history from newest to oldest
        })
    }
}
