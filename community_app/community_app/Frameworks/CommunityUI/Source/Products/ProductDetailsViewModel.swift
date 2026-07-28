//
//  ProductDetailsViewModel.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/26.
//

import Combine
import Foundation
import CommunityCore
import CoreLocation
import MapKit
import SwiftUI

@MainActor
public final class ProductDetailsViewModel: ProductDetailsViewModelProtocol {

    @Published public private(set) var state: ViewState<SupplierDetailResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]

    @Published public private(set) var supplierDetailResponse: SupplierDetailResponse?

    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    @Published public private(set) var isCreateProduct: Bool

    public var productURL: URL?

    private let product_id: String?

    private let router: NavigationRouter
    private let useCases: any SupplierUseCasesProvider
    private var fetchTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()

    public init(
        useCases: any SupplierUseCasesProvider,
        router: NavigationRouter,
        product_id: String?
    ) {
        self.useCases = useCases
        self.router = router
        self.product_id = product_id
        self.isCreateProduct = product_id == nil
        self.productURL = URL(string: "community-app://com.mistcreation.community-app/product/\(product_id ?? "")")!

        // Initialize authorization status based on current location service status
        self.isAuthorized = useCases.location.authorizationStatus == .authorizedAlways || useCases.location.authorizationStatus == .authorizedWhenInUse

        setupLocationObservers()
    }

    private func setupLocationObservers() {
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
    }

    public func productDetail() {
        
    }

    public func requestLocationAuthorization() async {
        do {
            try await useCases.location.requestLocationAuthorization()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    public func isFormValid(step: Int?) -> Bool {
        true
    }
}
