//
//  CreateMatchViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/01.
//

import MapKit
import Combine
import Foundation
import CommunityCore
import _MapKit_SwiftUI

public enum RegistrationSteps: Int {
    case step1 = 1
    case step2 = 2
    case step3 = 3
}

public enum Sport: String, CaseIterable, Identifiable {
    case soccer
    case padel
    
    public var id: String { self.rawValue }
    
    public var localizedName: String {
        switch self {
        case .soccer: return "Soccer"
        case .padel: return "Padel"
        }
    }
}

// MARK: - CreateMatchViewModelProtocol and CreateMatchViewModel

@MainActor
public protocol CreateMatchViewModelProtocol: ValidatableViewModel {
    var title: String { get set }
    var sport: Sport { get set }
    var duration: String { get set }
    var date_event: Date { get set }
    var time: Date { get set }
    var location: String { get set }
    var validatedLocationName: String { get set }
    var roster_size: String { get set }
    var cost: String { get set }
    var mapCameraPosition: MapCameraPosition { get set }
    var selectedLocationCoordinate: CLLocationCoordinate2D? { get set }
    
    func create()
    func searchLocation(query: String) async
}

@MainActor
public final class CreateMatchViewModel: CreateMatchViewModelProtocol {
    @Published public private(set) var state: ViewState<CreateMatchResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public var title = ""
    @Published public var sport: Sport = .soccer
    @Published public var duration = ""
    @Published public var date_event: Date = .now
    @Published public var time: Date = .now
    @Published public var location = "" // This stays bound to the TextField
    @Published public var validatedLocationName = "" // Store the official name here
    @Published public var roster_size = ""
    @Published public var cost = ""
    
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
              let validationStep = RegistrationSteps(rawValue: step) else {
            validationErrors["general"] = "Validation step could not be determined."
            return false
        }
        switch validationStep {
        case .step1:
            incompleteFormStep1()
        case .step2:
            incompleteFormStep2()
        case .step3:
            incompleteFormStep3()
        }
        return validationErrors.isEmpty
    }
    
    private let router: NavigationRouter
    private let useCases: any MatchUseCasesProvider
    private let mapSearchService: MapSearchServiceProtocol
    private var fetchTask: Task<Void, Never>?
    
    public init(
        useCases: any MatchUseCasesProvider,
        router: NavigationRouter,
        mapSearchService: MapSearchServiceProtocol
    ) {
        self.useCases = useCases
        self.router = router
        self.mapSearchService = mapSearchService
    }
    
    public func create() {
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: time)
                let minute = calendar.component(.minute, from: time)
                guard let combinedDate = calendar.date(bySettingHour: hour,
                                                       minute: minute,
                                                       second: 0,
                                                       of: date_event) else {
                    throw NSError(domain: "DateError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not combine date and time"])
                }
                
                // 2. Format the combined date to an ISO8601 string
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
                let isoString = isoFormatter.string(from: combinedDate)
                let request = CreateMatchRequest(
                    title: title,
                    sport: sport.rawValue,
                    duration: duration,
                    start_datetime: isoString,
                    location: validatedLocationName.isEmpty ? location : validatedLocationName,
                    latitude: selectedLocationCoordinate?.latitude ?? 0,
                    longitude: selectedLocationCoordinate?.longitude ?? 0,
                    roster_size: roster_size,
                    cost: cost
                )
                let response: CreateMatchResponse = try await useCases.matches.userCreateMatch(request)
                if !Task.isCancelled {
                    self.state = .success(response)
                    NotificationCenter.default.post(name: .matchCreated, object: nil)
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
        validateAndCollectError(forField: "title", value: title, nonEmptyMessage: "Title cannot be empty", in: &errors)
        // Validate either the raw input or the validated name if available
        let locationToValidate = validatedLocationName.isEmpty ? location : validatedLocationName
        validateAndCollectError(forField: "location", value: locationToValidate, nonEmptyMessage: "Location cannot be empty", in: &errors)
        self.validationErrors = errors
    }
    
    private func incompleteFormStep2() {
        var errors: [String: String] = [:]
        validateAndCollectError(forField: "duration", value: duration, nonEmptyMessage: "Duration cannot be empty", in: &errors)
        let calendar = Calendar.current
        let todayStartOfDay = calendar.startOfDay(for: Date())
        let selectedDateStartOfDay = calendar.startOfDay(for: date_event)
        if selectedDateStartOfDay < todayStartOfDay {
            errors["date_event"] = "Date cannot be in the past"
        }
        // No explicit validation for `time` as `Date` objects from UI pickers are usually valid.
        // If specific time constraints are needed (e.g., not too far in future/past), add them here.
        self.validationErrors = errors
    }
    
    private func incompleteFormStep3() {
        var errors: [String: String] = [:]
        validateAndCollectError(
            forField: "roster_size",
            value: roster_size,
            nonEmptyMessage: "Roster size cannot be empty",
            numericValidator: { [weak self] val in self?.validatePositiveInteger(value: val, fieldName: "Roster size") },
            in: &errors
        )
        validateAndCollectError(
            forField: "cost",
            value: cost,
            nonEmptyMessage: "Cost cannot be empty",
            numericValidator: { [weak self] val in self?.validateNonNegativeDouble(value: val, fieldName: "Cost") },
            in: &errors
        )
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
            let mapItems = try await mapSearchService.search(query: query)
            
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
            //            print("Search error: \(error)") // Keeping original comment for context
            self.selectedLocationCoordinate = nil // Clear marker on error
            self.validatedLocationName = "" // Clear validated name on error
        }
    }
}
