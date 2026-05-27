//
//  LocationService.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/05/26.
//

import CoreLocation
import CommunityCore
import Combine

/// Concrete implementation of MapSearchServiceProtocol using MKLocalSearch.
@MainActor 
public final class LocationService: NSObject, LocationProtocol, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published public var lastKnownLocation: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus?

    // Remove 'nonisolated' since the class is now @MainActor
    public override init() {
        super.init() // Call super.init() first to fix the error
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    public func lastKnownLocation() async throws {
        locationManager.requestLocation()
    }

    public func requestLocationAuthorization() async throws {
        locationManager.requestWhenInUseAuthorization()
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation() // Get an initial location if authorized
        case .denied, .restricted:
            print("Location access denied or restricted.")
            // You might want to show an alert to the user here
        case .notDetermined:
            print("Location authorization not determined.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location
        // If you only need a single update, you can stop updates here:
         manager.stopUpdatingLocation()
    }

    // Crucial: Implement the didFailWithError delegate method for robust error handling.
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        // You might want to update a published property here to notify about location errors.
    }
}
