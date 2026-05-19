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
    var isTogglingParticipation: Bool { get }
    var isTogglingCancellation: Bool { get }
    func matchDetail()
    func toggle_match_participation()
    func toggle_match_cancellation()
}

@MainActor
public final class MatchDetailsViewModel: MatchDetailsViewModelProtocol {
    @Published public private(set) var state: ViewState<MatchDetailResponse> = .idle
    @Published public private(set) var isTogglingParticipation: Bool = false
    @Published public private(set) var isTogglingCancellation: Bool = false
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
        // Automatically fetch match details when the ViewModel is initialized
        matchDetail()
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

        if var currentMatchDetail = self.matchDetailResponse {
            isTogglingParticipation = true
            fetchTask?.cancel()
            fetchTask = Task {
                defer { isTogglingParticipation = false }

                do {
                    let participationResponse: ParticipationResponse = try await useCases.matches.toggleParticipation(.init(match_id))
                    if !Task.isCancelled {
                        currentMatchDetail.is_joined = participationResponse.is_joined
                        currentMatchDetail.current_roster = participationResponse.current_roster
                        currentMatchDetail.player_list = participationResponse.player_list
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

    public func toggle_match_cancellation() {
        guard !isTogglingCancellation else { return }

        if var currentMatchDetail = self.matchDetailResponse {
            isTogglingCancellation = true
            fetchTask?.cancel()
            fetchTask = Task {
                defer { isTogglingCancellation = false }

                do {
                    let cancellationResponse: CancellationResponse = try await useCases.matches.toggleCancellation(.init(match_id))
                    if !Task.isCancelled {
                        currentMatchDetail.is_cancelled = cancellationResponse.is_cancelled
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
