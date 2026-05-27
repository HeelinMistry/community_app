//
//  LocationProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/05/26.
//

import CoreLocation

/// Protocol for a location service, allowing for mocking in tests.
public protocol LocationProtocol: Sendable {
    var authorizationStatus: CLAuthorizationStatus? { get }
    var lastKnownLocation: CLLocation? { get }
    
    func lastKnownLocation() async throws
    func requestLocationAuthorization() async throws 
}
