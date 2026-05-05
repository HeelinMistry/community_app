//
//  CreateMatchViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/01.
//

import Combine
import Foundation
import CommunityCore

public enum RegistrationSteps: Int {
    case step1 = 1
    case step2 = 2
    case step3 = 3
}

@MainActor
public protocol CreateMatchViewModelProtocol: ValidatableViewModel {
    var title: String { get set }
    var sport: String { get set }
    var duration: String { get set }
    var date_event: Date { get set }
    var time: String { get set }
    var location: String { get set }
    var roster_size: String { get set }
    var cost: String { get set }
    
    func create()
}

@MainActor
public final class CreateMatchViewModel: CreateMatchViewModelProtocol {
    @Published public private(set) var state: ViewState<CreateMatchResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public var title = ""
    @Published public var sport = ""
    @Published public var duration = ""
    @Published public var date_event: Date = .now
    @Published public var time = ""
    @Published public var location = ""
    @Published public var roster_size = ""
    @Published public var cost = ""
    
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
    private var fetchTask: Task<Void, Never>?
    
    public init(
        useCases: any MatchUseCasesProvider,
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
                let dateFormatter: DateFormatter = {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
//                    formatter.locale = Locale(identifier: "en_US_POSIX") // Consider setting locale/timezone explicitly for consistency
//                    formatter.timeZone = TimeZone(secondsFromGMT: 0) // Or your desired timezone
                    return formatter
                }()
//                let dateString = dateFormatter.string(from: date_event)

//                let request = CreateMatchRequest(
//                    title: title,
//                    sport: sport,
//                    duration: duration,
//                    date_event: dateString,
//                    time: time,
//                    location: location,
//                    roster_size: roster_size,
//                    cost: cost
//                )
                let request: CreateMatchRequest = .init()
                let response: CreateMatchResponse = try await useCases.matches.userCreateMatch(request)
                if !Task.isCancelled {
                    self.state = .success(response)
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
        validateAndCollectError(forField: "sport", value: sport, nonEmptyMessage: "Sport cannot be empty", in: &errors)
        validateAndCollectError(forField: "location", value: location, nonEmptyMessage: "Location cannot be empty", in: &errors)
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
        validateAndCollectError(forField: "time", value: time, nonEmptyMessage: "Time cannot be empty", in: &errors)
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
}
