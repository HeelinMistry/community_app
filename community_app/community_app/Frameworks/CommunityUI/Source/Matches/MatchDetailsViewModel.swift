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
import UserNotifications 
import SwiftUI

@MainActor
public final class MatchDetailsViewModel: MatchDetailsViewModelProtocol {
    
    @Published public private(set) var state: ViewState<MatchDetailResponse> = .idle
    @Published public private(set) var isTogglingParticipation: Bool = false
    @Published public private(set) var isTogglingCancellation: Bool = false
    @Published public private(set) var matchDetailResponse: MatchDetailResponse?
    
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    @Published public private(set) var isSchedulingNotification: Bool = false
    @Published public private(set) var isNotificationScheduled: Bool = false
    
    public var matchURL: URL
    
    private let match_id: String
    
    private let router: NavigationRouter
    private let useCases: any MatchDetailUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        useCases: any MatchDetailUseCasesProvider,
        router: NavigationRouter,
        match_id: String
    ) {
        self.useCases = useCases
        self.router = router
        self.match_id = match_id
        
        self.matchURL = URL(string: "community-app://com.mistcreation.community-app/match/\(match_id)")!
        
        self.isAuthorized = useCases.location.authorizationStatus == .authorizedAlways || useCases.location.authorizationStatus == .authorizedWhenInUse
        
        setupLocationObservers()
    }
    
    private func setupLocationObservers() {
        useCases.location.authorizationStatusPublisher
            .sink { [weak self] status in
                guard let self = self else { return }
                self.isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
            }
            .store(in: &cancellables)
        
        useCases.location.lastKnownLocationPublisher
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
            fetchTask = Task { @MainActor in
                defer { isTogglingParticipation = false }
                
                do {
                    let participationResponse: ParticipationResponse = try await useCases.matches.toggleParticipation(.init(match_id))
                    if !Task.isCancelled {
                        currentMatchDetail.is_joined = participationResponse.is_joined
                        currentMatchDetail.current_roster = participationResponse.current_roster
                        currentMatchDetail.player_list = participationResponse.player_list
                        self.matchDetailResponse = currentMatchDetail
                        self.state = .success(currentMatchDetail)
                        
                        // If the user is leaving the match, remove the scheduled notification
                        if !participationResponse.is_joined {
                            useCases.notifications.cancelMatchNotification(id: match_id)
                                self.isNotificationScheduled = false
                        }
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
            try await useCases.location.requestLocationAuthorization()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func showDirectionsOnMap() {
        guard (useCases.location.lastKnownLocation) != nil else {
            self.state = .error("Your current location is not available.")
            return
        }
        
        guard let match = matchDetailResponse else {
            self.state = .error("Match details not available.")
            return
        }
        
        let destination = CLLocationCoordinate2D(latitude: match.latitude, longitude: match.longitude)
        
        // Delegate to the service
        useCases.location.openDirections(to: destination, destinationName: match.location)
    }
    
    public func scheduleMatchNotification() {
        guard !isSchedulingNotification else { return }
        isSchedulingNotification = true
        
        Task { @MainActor in
            defer { isSchedulingNotification = false }
            guard let match = matchDetailResponse else { return }

            do {
                try await useCases.notifications.requestAuthorization()
                
                let result = try await useCases.notifications.scheduleMatchNotification(
                    id: match_id,
                    title: match.title,
                    location: match.location,
                    startDate: formatDate(match.start_datetime)
                )
                
                router.alertItem = .init(title: "Success", message: result.message, dismissButton: .cancel())
                isNotificationScheduled = true
            } catch {
                router.alertItem = .init(title: "Error", message: error.localizedDescription, dismissButton: .cancel())
                isNotificationScheduled = false
            }
        }
    }
    
    private func formatDate(_ isoString: String) -> Date {
        if let date = Self.isoDateFormatter.date(from: isoString) {
            return date
        }
        return Date()
    }
    
    static var isoDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }
}
