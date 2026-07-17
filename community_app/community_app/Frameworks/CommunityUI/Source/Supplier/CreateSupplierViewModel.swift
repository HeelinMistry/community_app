//
//  CreateSupplierViewModel.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/11.
//

import MapKit
import Combine
import Foundation
import CommunityCore
import _MapKit_SwiftUI

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

// MARK: - CreateMatchViewModelProtocol and CreateMatchViewModel

@MainActor
public protocol CreateSupplierViewModelProtocol: ValidatableViewModel {
    var business_name: String { get set }
    var category: SupplierCategory { get set }
    var description: String { get set }
    var location: String { get set }
    var validatedLocationName: String { get set }
    var service_radius: String { get set }
    var mapCameraPosition: MapCameraPosition { get set }
    var selectedLocationCoordinate: CLLocationCoordinate2D? { get set }
    
    func create()
    func searchLocation(query: String) async
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
    @Published public var service_radius = ""
    
    // Initial map position, matching the default in CreateMatchView
    @Published public var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -25.86, longitude: 28.18),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    // Stores the coordinate for the map marker
    @Published public var selectedLocationCoordinate: CLLocationCoordinate2D?
    
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
    }
    
    public func create() {
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                
                let request = CreateSupplierRequest(
                    business_name: business_name,
                    description: "test",
                    category: category.rawValue,
                    latitude: selectedLocationCoordinate?.latitude ?? 0,
                    longitude: selectedLocationCoordinate?.longitude ?? 0,
                    service_radius: 5.1
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
        // Validate either the raw input or the validated name if available
        let locationToValidate = validatedLocationName.isEmpty ? location : validatedLocationName
        validateAndCollectError(forField: "location", value: locationToValidate, nonEmptyMessage: "Location cannot be empty", in: &errors)
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
    
    public func searchLocation(query: String) async {
        guard !query.isEmpty else {
            // Reset map to default or current known location if query is empty
            self.mapCameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -25.86, longitude: 28.18),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
            self.selectedLocationCoordinate = nil // Clear the marker
            self.validatedLocationName = "" // Clear validated name
            return
        }
        
        do {
            let mapItems = try await useCases.location.search(query: query)
            
            if let item = mapItems.first {
                // DO NOT overwrite self.location here, it's bound to the TextField
                self.validatedLocationName = item.name ?? query // Store the official name
                
                // Update map camera position to show the result
                let coordinate = item.placemark.coordinate
                self.mapCameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // Zoom in a bit more
                ))
                self.selectedLocationCoordinate = coordinate // Set the coordinate for the marker
            } else {
                // If no item found, clear the marker and validated location name
                self.selectedLocationCoordinate = nil
                self.validatedLocationName = ""
                // Keep the user's typed location in the `location` text field
            }
        } catch {
            self.selectedLocationCoordinate = nil // Clear marker on error
            self.validatedLocationName = "" // Clear validated name on error
        }
    }
}
