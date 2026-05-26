//
//  LocationManager.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/05/26.
//

import CoreLocation
import Foundation
import Combine // Don't forget to import Combine for @Published

public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published public var lastKnownLocation: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus?

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced // Good for general location, less battery intensive
    }

    public func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    public func requestLocation() {
        // Request a one-time location update.
        // If you need continuous updates, use locationManager.startUpdatingLocation()
        // and remember to stop it with locationManager.stopUpdatingLocation() when no longer needed.
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

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
        // manager.stopUpdatingLocation()
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
