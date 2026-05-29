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
import MapKit

@MainActor
public final class MatchDetailsViewModel: MatchDetailsViewModelProtocol {
    
    @Published public private(set) var state: ViewState<MatchDetailResponse> = .idle
    @Published public private(set) var isTogglingParticipation: Bool = false
    @Published public private(set) var isTogglingCancellation: Bool = false
    @Published public private(set) var matchDetailResponse: MatchDetailResponse?
    
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
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
        
        self.lastKnownLocation = locationService.lastKnownLocation
        self.isAuthorized = locationService.authorizationStatus == .authorizedAlways || locationService.authorizationStatus == .authorizedWhenInUse
        
        setupLocationObservers()
    }
    
    private func setupLocationObservers() {
        locationService.authorizationStatusPublisher
            .sink { [weak self] status in
                guard let self = self else { return }
                self.isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
            }
            .store(in: &cancellables)
        
        locationService.lastKnownLocationPublisher
            .sink { [weak self] location in
                self?.lastKnownLocation = location
            }
            .store(in: &cancellables)
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
    
    public func requestLocationAuthorization() async {
        do {
            try await locationService.requestLocationAuthorization()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func showDirectionsOnMap() {
        guard let lastKnownLocation = lastKnownLocation else {
            self.state = .error("Your current location is not available to show directions. Please enable location services and try again.")
            return
        }
        
        guard let matchDetail = matchDetailResponse else {
            self.state = .error("Match details are not available to show directions. Please ensure match data is loaded.")
            return
        }
    
        let destinationCoordinate = CLLocationCoordinate2D(latitude: matchDetail.latitude, longitude: matchDetail.longitude)
        
        let sourcePlacemark = MKPlacemark(coordinate: lastKnownLocation.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        sourceMapItem.name = "Your Location" // You can customize this name
        
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        destinationMapItem.name = matchDetail.location // Use the match's provided location name
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
        MKMapItem.openMaps(with: [sourceMapItem, destinationMapItem], launchOptions: launchOptions)
    }
}
