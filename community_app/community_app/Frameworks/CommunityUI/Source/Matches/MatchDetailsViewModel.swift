//
//  MatchDetailsViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/14.
//

import Combine
import Foundation
import CommunityCore
import CoreLocation

@MainActor
public protocol MatchDetailsViewModelProtocol: StateDrivenViewModel where DataType == MatchDetailResponse {
    var matchURL: URL { get }
    var matchDetailResponse: MatchDetailResponse? { get }
    var isTogglingParticipation: Bool { get }
    var isTogglingCancellation: Bool { get }
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    
    func matchDetail()
    func toggleMatchParticipation()
    func toggleMatchCancellation()
    func requestLocationAuthorization() async
}

@MainActor
public final class MatchDetailsViewModel: MatchDetailsViewModelProtocol {
    
    @Published public private(set) var state: ViewState<MatchDetailResponse> = .idle
    @Published public private(set) var isTogglingParticipation: Bool = false
    @Published public private(set) var isTogglingCancellation: Bool = false
    @Published public private(set) var matchDetailResponse: MatchDetailResponse?
    
    public var matchURL: URL
    
    private let match_id: String
    
    private let router: NavigationRouter
    private let useCases: any MatchUseCasesProvider
    private let locationService: LocationProtocol
    private var fetchTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        useCases: any MatchUseCasesProvider,
        router: NavigationRouter,
        match_id: String,
        locationService: LocationProtocol
    ) {
        self.useCases = useCases
        self.router = router
        self.match_id = match_id
        self.locationService = locationService
        
        self.matchURL = URL(string: "community-app://com.mistcreation.community-app/match/\(match_id)")!
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
    
    public func toggleMatchParticipation() {
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
    
    public func toggleMatchCancellation() {
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
    
    public var lastKnownLocation: CLLocation? {
        locationService.lastKnownLocation
    }
    
    public var isAuthorized: Bool {
        locationService.authorizationStatus == .authorizedAlways || locationService.authorizationStatus == .authorizedWhenInUse
    }
    
    public func requestLocationAuthorization() async {
        do {
            try await locationService.requestLocationAuthorization()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

}
