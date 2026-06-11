//
//  LocationProtocol.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/05/26.
//

import CoreLocation
import Combine
import MapKit

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

    /// Opens the native Maps app with directions from current location to the target.
    func openDirections(to coordinate: CLLocationCoordinate2D, destinationName: String)
    
    /// Searches for map items based on a given query string.
    /// - Parameter query: The natural language query string to search for.
    /// - Returns: An array of `MKMapItem` objects matching the query.
    /// - Throws: An error if the search operation fails.
    func search(query: String) async throws -> [MKMapItem]
}
