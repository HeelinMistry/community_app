//
//  ReviewViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/09/26.
//

import MapKit
import SwiftUI
import Combine
import Foundation
import CommunityCore

public enum ReviewSteps: Int {
    case step1 = 1
}

// MARK: - ReviewViewModelProtocol and ReviewViewModel

@MainActor
public protocol ReviewViewModelProtocol: ValidatableViewModel {
    var comment: String { get set }
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    
    func requestLocationAuthorization() async
    func review()
}

@MainActor
public final class ReviewViewModel: ReviewViewModelProtocol {
    @Published public private(set) var state: ViewState<CreateSupplierResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public var comment = ""
    
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    private var cancellables = Set<AnyCancellable>()
    
    public func isFormValid(step: Int? = nil) -> Bool {
        validationErrors = [:]
        return validationErrors.isEmpty
    }
    
    private let router: NavigationRouter
    private let useCases: any SupplierUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    public init(
        useCases: any SupplierUseCasesProvider,
        router: NavigationRouter,
        id: String
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
    
    public func review() {
        fetchTask?.cancel()
        state = .loading
    }
    
    private func incompleteFormStep1() {
    }
}
