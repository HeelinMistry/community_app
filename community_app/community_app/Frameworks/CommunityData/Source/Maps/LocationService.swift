//
//  LocationService.swift
//  CommunityData
//
//  Created by Heelin Mistry on 2026/05/26.
//

import CoreLocation
import CommunityCore
import Combine
import MapKit

/// Concrete implementation of MapSearchServiceProtocol using MKLocalSearch.
@MainActor
public final class LocationService: NSObject, LocationProtocol, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published public var authorizationStatus: CLAuthorizationStatus?
    @Published public var lastKnownLocation: CLLocation?
    
    public var authorizationStatusPublisher: AnyPublisher<CLAuthorizationStatus?, Never> {
        $authorizationStatus.eraseToAnyPublisher()
    }
    public var lastKnownLocationPublisher: AnyPublisher<CLLocation?, Never> {
        $lastKnownLocation.eraseToAnyPublisher()
    }
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        
        // Initialize published properties with current status if available
        authorizationStatus = locationManager.authorizationStatus
        
        // Request an initial location if permission is already granted when the service starts
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        print("LocationService Instance: \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    public func requestLocationAuthorization() async throws {
        // Explicitly run on MainActor to satisfy Swift 6 strict concurrency
        await MainActor.run {
            locationManager.requestWhenInUseAuthorization()
        }
        // `locationManagerDidChangeAuthorization` will be called after this,
        // handling the update of `authorizationStatus` and subsequent `requestLocation()` if authorized.
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus // Update published property
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation() // Get an initial location if authorized
        case .denied, .restricted:
            print("Location access denied or restricted.")
            lastKnownLocation = nil // Clear last known location if denied/restricted
            // You might want to show an alert to the user here
        case .notDetermined:
            print("Location authorization not determined.")
        @unknown default:
            print("Unknown authorization status.")
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.lastKnownLocation = location
            print("Updated lastKnownLocation to: \(location.coordinate)")
        }
        
        // If you only need a single update, you can stop updates here:
         manager.stopUpdatingLocation() // `requestLocation()` automatically stops after a single update.
    }
    
    // Crucial: Implement the didFailWithError delegate method for robust error handling.
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        // Consider publishing an error state or clearing location if appropriate
        lastKnownLocation = nil // Clear location on error
    }
    
    public func openDirections(to coordinate: CLLocationCoordinate2D, destinationName: String) {
        guard let currentLocation = lastKnownLocation else { return }
        
        let sourcePlacemark = MKPlacemark(coordinate: currentLocation.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: coordinate)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        sourceMapItem.name = "Your Location"
        
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        destinationMapItem.name = destinationName
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
        MKMapItem.openMaps(with: [sourceMapItem, destinationMapItem], launchOptions: launchOptions)
    }
    
    /// Searches for map items using `MKLocalSearch` based on a given query string.
    /// - Parameter query: The natural language query string to search for.
    /// - Returns: An array of `MKMapItem` objects matching the query.
    /// - Throws: An error if the `MKLocalSearch` operation fails.
    public func search(query: String) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }
}
