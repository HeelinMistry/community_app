//
//  LocationProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/05/26.
//

import CoreLocation
import Combine

/// A protocol defining the interface for location services, including authorization status and last known location.
public protocol LocationProtocol {
    /// The current authorization status for location services.
    var authorizationStatus: CLAuthorizationStatus? { get }
    /// The last known location of the device.
    var lastKnownLocation: CLLocation? { get }
    
    /// A publisher that emits changes to the authorization status for location services.
    var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus?, Never> { get }
    /// A publisher that emits the last known location of the device when it changes.
    var lastKnownLocationPublisher: AnyPublisher<CLLocation?, Never> { get }
    
    /// Requests authorization to use location services.
    /// - Throws: An error if authorization cannot be requested or fails.
    func requestLocationAuthorization() async throws
    // Location updates are handled by requestLocationAuthorization and delegate callbacks.
}
