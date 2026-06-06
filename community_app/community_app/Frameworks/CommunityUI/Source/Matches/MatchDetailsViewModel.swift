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
    
    public func scheduleMatchNotification() {
        guard !isSchedulingNotification else { return }
        isSchedulingNotification = true
        
        Task { @MainActor in
            defer { isSchedulingNotification = false }
            
            guard let matchDetail = matchDetailResponse else {
                router.alertItem = .init(title: "Error", message: "Match details not available to schedule notification.", dismissButton: .cancel())
                return
            }
            
            // 1. Request notification authorization
            let center = UNUserNotificationCenter.current()
            do {
                let settings = await center.notificationSettings()
                guard settings.authorizationStatus == .authorized else {
                    // Not authorized or denied, request authorization
                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                    guard granted else {
                        router.alertItem = .init(title: "Permission Denied", message: "Notification permission was denied. Please enable notifications in Settings to receive match reminders.", dismissButton: .cancel())
                        isNotificationScheduled = false
                        return
                    }
                    // If granted here, proceed
                    return
                }
            } catch {
                router.alertItem = .init(title: "Error", message: "Failed to get notification settings or request authorization: \(error.localizedDescription)", dismissButton: .cancel())
                isNotificationScheduled = false
                return
            }
            
            // 2. Combine date_event and time into a single Date for the match start
            let calendar = Calendar.current
            let date = formatDate(matchDetail.start_datetime)
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
            
            var matchStartComponents = DateComponents()
            matchStartComponents.year = dateComponents.year
            matchStartComponents.month = dateComponents.month
            matchStartComponents.day = dateComponents.day
            matchStartComponents.hour = timeComponents.hour
            matchStartComponents.minute = timeComponents.minute
            
            guard let matchStartDate = calendar.date(from: matchStartComponents) else {
                router.alertItem = .init(title: "Error", message: "Could not determine match start date for notification.", dismissButton: .cancel())
                isNotificationScheduled = false
                return
            }
            
            // Ensure the match date is in the future
            guard matchStartDate > Date.now else {
                router.alertItem = .init(title: "Info", message: "This match has already started or passed. Cannot schedule a future notification.", dismissButton: .cancel())
                isNotificationScheduled = false
                return
            }
            
            // 3. Calculate notification time (e.g., 15 minutes before the match)
            guard let notificationDate = calendar.date(byAdding: .minute, value: -15, to: matchStartDate) else {
                router.alertItem = .init(title: "Error", message: "Could not calculate notification time.", dismissButton: .cancel())
                isNotificationScheduled = false
                return
            }
            
            // Determine the actual date for the trigger. If 15 mins before is already in the past,
            // schedule for the match start time, as long as it's still in the future.
            let finalTriggerDate: Date
            if notificationDate <= Date.now {
                finalTriggerDate = matchStartDate
                router.alertItem = .init(title: "Heads up!", message: "The 15-minute reminder time has passed. Scheduling reminder for the match start time instead.", dismissButton: .cancel())
            } else {
                finalTriggerDate = notificationDate
                router.alertItem = .init(title: "Success", message: "Match reminder scheduled for 15 minutes before the match!", dismissButton: .cancel())
            }

            // 4. Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Upcoming Match: \(matchDetail.title)"
            content.body = "Your match at \(matchDetail.location) is starting \(finalTriggerDate == matchStartDate ? "now" : "in 15 minutes")!"
            content.sound = .default
            
            // Add user info to open the match deep link if desired
            content.userInfo = ["match_id": match_id]
            
            // 5. Create UNCalendarNotificationTrigger
            let triggerDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: finalTriggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            // 6. Create UNNotificationRequest
            let requestIdentifier = "match-reminder-\(matchDetail.title)"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            
            // 7. Add request to notification center
            do {
                try await center.add(request)
                isNotificationScheduled = true
            } catch {
                router.alertItem = .init(title: "Error", message: "Failed to schedule match notification: \(error.localizedDescription)", dismissButton: .cancel())
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
