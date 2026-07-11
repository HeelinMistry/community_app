//
//  DashboardViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Combine
import Foundation
import CommunityCore
import CoreLocation
import MapKit

@MainActor
public protocol DashboardViewModelProtocol: StateDrivenViewModel where DataType == DashboardModel {
    
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    
    var dashboardModel: DashboardModel { get }
    
    func matchFeed()
    func createMatchTapped()
    
    func nearbySuppliers()
}

@MainActor
public final class DashboardViewModel: DashboardViewModelProtocol {
    @Published public private(set) var state: ViewState<DashboardModel> = .idle
    
    @Published public private(set) var dashboardModel: DashboardModel = .init()
    
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    private let router: NavigationRouter
    private let useCases: any DashboardUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        useCases: any DashboardUseCasesProvider,
        router: NavigationRouter
    ) {
        self.useCases = useCases
        self.router = router
        self.isAuthorized = useCases.location.authorizationStatus == .authorizedAlways || useCases.location.authorizationStatus == .authorizedWhenInUse
        setupObservers()
        matchFeed()
    }
    
    private func setupObservers() {
        useCases.location.authorizationStatusPublisher
            .sink { [weak self] status in
                guard let self = self else { return }
                self.isAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
            }
            .store(in: &cancellables)
        useCases.location.lastKnownLocationPublisher
            .sink { [weak self] location in
                self?.lastKnownLocation = location
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .matchCreated)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.matchFeed()
            }
            .store(in: &cancellables)
    }
    
    public func matchFeed() {
        if state == .loading {
            return
        }
        
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                let response: Matches = try await useCases.matches.userRelatedMatches()
                if !Task.isCancelled {
                    dashboardModel.update(matches: response)
                    state = .success(dashboardModel)
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    public func nearbySuppliers() {
        if state == .loading {
            return
        }
        
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                let request: SupplierRequest = .init(
                    lat: lastKnownLocation?.coordinate.latitude ?? 0,
                    lon: lastKnownLocation?.coordinate.longitude ?? 0,
                    user_radius: 5.0
                )
                let response: Suppliers = try await useCases.suppliers.nearbySuppliers(request)
                if !Task.isCancelled {
                    dashboardModel.update(suppliers: response)
                    state = .success(dashboardModel)
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    public func createMatchTapped() {
        router.sheet = .createMatch
    }
}
