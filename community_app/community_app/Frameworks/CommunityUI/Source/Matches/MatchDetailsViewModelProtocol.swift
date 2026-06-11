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
public protocol MatchDetailsViewModelProtocol: StateDrivenViewModel where DataType == MatchDetailResponse {
    var matchURL: URL { get }
    var matchDetailResponse: MatchDetailResponse? { get }
    var isTogglingParticipation: Bool { get }
    var isTogglingCancellation: Bool { get }
    
    // Properties for notification scheduling
    var isSchedulingNotification: Bool { get }
    var isNotificationScheduled: Bool { get }
    var isCancellingNotification: Bool { get }
    
    var lastKnownLocation: CLLocation? { get } 
    var isAuthorized: Bool { get }
    
    func matchDetail()
    func toggleMatchParticipation()
    func toggleMatchCancellation()
    func requestLocationAuthorization() async
    func showDirectionsOnMap()
    
    func scheduleMatchNotification() async
    func cancelMatchNotification() async
}
