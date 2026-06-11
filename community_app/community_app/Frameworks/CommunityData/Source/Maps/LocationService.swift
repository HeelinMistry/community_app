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
        
        // Initialize published properties with current status if available
        authorizationStatus = locationManager.authorizationStatus
        
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    public func requestLocationAuthorization() async throws {
        await MainActor.run {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus 
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            print("Started Updating Location")
        case .denied, .restricted:
            print("Location access denied or restricted.")
            manager.stopUpdatingLocation()
            lastKnownLocation = nil
            // You might want to show an alert to the user here
        case .notDetermined:
            print("Location authorization not determined.")
            // No action needed here, authorization request will handle starting updates.
        @unknown default:
            print("Unknown authorization status.")
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.lastKnownLocation = location
        }
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
