//
//  CreateSupplierViewModel.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/11.
//

import MapKit
import SwiftUI
import Combine
import Foundation
import CommunityCore

public enum CreateSupplierSteps: Int {
    case step1 = 1
}

public enum SupplierCategory: String, CaseIterable, Identifiable {
    case homeLifestyle
    case professionalServices
    case maintenanceCare
    case creativeCrafts
    
    public var id: String { self.rawValue }
    
    public var localizedName: String {
        switch self {
        case .homeLifestyle: return "Home & Lifestyle"
        case .professionalServices: return "Professional Services"
        case .maintenanceCare: return "Maintenance & Care"
        case .creativeCrafts: return "Creative & Crafts"
        }
    }
}

// MARK: - CreateSupplierViewModelProtocol and CreateSupplierViewModel

@MainActor
public protocol CreateSupplierViewModelProtocol: ValidatableViewModel {
    var business_name: String { get set }
    var category: SupplierCategory { get set }
    var description: String { get set }
    var location: String { get set }
    var validatedLocationName: String { get set }
    var service_radius: Double { get set }
    var mapCameraPosition: MapCameraPosition { get set }
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    
    func requestLocationAuthorization() async
    func create()
}

@MainActor
public final class CreateSupplierViewModel: CreateSupplierViewModelProtocol {
    @Published public private(set) var state: ViewState<CreateSupplierResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public var business_name = ""
    @Published public var category: SupplierCategory = .homeLifestyle
    @Published public var description = ""
    @Published public var location = "" // This stays bound to the TextField
    @Published public var validatedLocationName = "" // Store the official name here
    @Published public var service_radius: Double = 5000.0 // Changed to Double, default 5km (5000 meters)
    
    // Initial map position, matching the default in CreateMatchView
    @Published public var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -25.86, longitude: 28.18), // Default South Africa location
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    private var cancellables = Set<AnyCancellable>()
    
    public func isFormValid(step: Int? = nil) -> Bool {
        validationErrors = [:]
        guard let step,
              let validationStep = CreateSupplierSteps(rawValue: step) else {
            validationErrors["general"] = "Validation step could not be determined."
            return false
        }
        switch validationStep {
        case .step1:
            incompleteFormStep1()
        }
        return validationErrors.isEmpty
    }
    
    private let router: NavigationRouter
    private let useCases: any SupplierUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    public init(
        useCases: any SupplierUseCasesProvider,
        router: NavigationRouter
    ) {
        self.useCases = useCases
        self.router = router
        self.isAuthorized = useCases.location.authorizationStatus == .authorizedAlways || useCases.location.authorizationStatus == .authorizedWhenInUse
        setupObservers()
    }
    
    private func setupObservers() {
        useCases.location.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                print("Authorization received: \(String(describing: status))")
                guard let self = self else { return }
                self.isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
            }
            .store(in: &cancellables)
        
        useCases.location.lastKnownLocationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                print("Location received: \(String(describing: location))")
                self?.lastKnownLocation = location
                if let newLocation = location {
                    // Only update the map camera if it's currently at the default South Africa location
                    // or if this is the first time we're receiving a location.
                    // This prevents overriding user's manual map interaction after they've moved it.
                    let defaultCenter = CLLocationCoordinate2D(latitude: -25.86, longitude: 28.18)
                    let currentMapCenter = self?.mapCameraPosition.region?.center
                    
                    if (currentMapCenter?.latitude == defaultCenter.latitude &&
                        currentMapCenter?.longitude == defaultCenter.longitude) ||
                        self?.lastKnownLocation == nil {
                        self?.mapCameraPosition = .camera(MapCamera(centerCoordinate: newLocation.coordinate, distance: 10000)) // 10km distance
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    public func requestLocationAuthorization() async {
        do {
            try await useCases.location.requestLocationAuthorization()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    public func create() {
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                // Assuming CreateSupplierRequest expects service_radius in kilometers (based on initial 5.1 value)
                let serviceRadiusInKilometers = service_radius / 1000.0 
                
                let request = CreateSupplierRequest(
                    business_name: business_name,
                    description: description, // Changed from hardcoded "test" to use the ViewModel's property
                    category: category.rawValue,
                    latitude: lastKnownLocation?.coordinate.latitude ?? 0,
                    longitude: lastKnownLocation?.coordinate.longitude ?? 0,
                    service_radius: serviceRadiusInKilometers
                )
                let response: CreateSupplierResponse = try await useCases.suppliers.userCreateSupplier(request)
                if !Task.isCancelled {
                    self.state = .success(response)
                    NotificationCenter.default.post(name: .supplierCreated, object: nil)
                    router.sheet = nil
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                    self.validationErrors["general"] = "Failed to create match: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func incompleteFormStep1() {
        var errors: [String: String] = [:]
        validateAndCollectError(forField: "business_name", value: business_name, nonEmptyMessage: "Business name cannot be empty", in: &errors)
        // MARK: - New Description Validation
        validateAndCollectError(forField: "description", value: description, nonEmptyMessage: "Description cannot be empty", in: &errors)
        
        // Revised Location Validation: Check for authorization and last known location
        if !isAuthorized {
            errors["location"] = "Location services are required. Please enable in Settings."
        } else if lastKnownLocation == nil {
            errors["location"] = "Your current location is not available. Please ensure GPS is active and permissions are granted."
        }

        // Validate service_radius
        if service_radius < 100 { // Minimum 100 meters
            errors["service_radius"] = "Service radius must be at least 0.1 km."
        } else if service_radius > 50000 { // Maximum 50 km
            errors["service_radius"] = "Service radius cannot exceed 50 km."
        }
        
        self.validationErrors = errors
    }
    
    // MARK: - Validation Helpers
    
    private func validatePositiveInteger(value: String, fieldName: String) -> String? {
        guard !value.isEmpty else { return nil }
        if let intValue = Int(value), intValue > 0 {
            return nil
        }
        return "\(fieldName) must be a positive number"
    }
    
    private func validateNonNegativeDouble(value: String, fieldName: String) -> String? {
        guard !value.isEmpty else { return nil }
        if let doubleValue = Double(value), doubleValue >= 0 {
            return nil
        }
        return "\(fieldName) must be a non-negative number"
    }
    
    private func validateAndCollectError(
        forField key: String,
        value: String,
        nonEmptyMessage: String,
        numericValidator: ((String) -> String?)? = nil,
        in errors: inout [String: String]
    ) {
        if value.isEmpty {
            errors[key] = nonEmptyMessage
        } else if let numericValidator = numericValidator, let error = numericValidator(value) {
            errors[key] = error
        }
    }
}
