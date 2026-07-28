import Combine
import Foundation
import CommunityCore
import CoreLocation
import MapKit
import SwiftUI

@MainActor
public final class SupplierDetailsViewModel: SupplierDetailsViewModelProtocol {

    @Published public private(set) var state: ViewState<SupplierDetailResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]

    @Published public private(set) var supplierDetailResponse: SupplierDetailResponse?

    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool

    public var supplierURL: URL

    private let supplier_id: String

    private let router: NavigationRouter
    private let useCases: any SupplierUseCasesProvider
    private var fetchTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()

    public init(
        useCases: any SupplierUseCasesProvider,
        router: NavigationRouter,
        supplier_id: String
    ) {
        self.useCases = useCases
        self.router = router
        self.supplier_id = supplier_id

        self.supplierURL = URL(string: "community-app://com.mistcreation.community-app/supplier/\(supplier_id)")!

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

    public func supplierDetail() {
        if state == .loading {
            return
        }

        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                // Call the use case to fetch supplier details
                let response: SupplierDetailResponse = try await useCases.suppliers.selectedSupplierDetails(.init(supplier_id))
                supplierDetailResponse = response
                if !Task.isCancelled {
                    if let supplierDetailResponse {
                        self.state = .success(supplierDetailResponse)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    public func requestLocationAuthorization() async {
        do {
            try await useCases.location.requestLocationAuthorization()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    public func showDirectionsOnMap() {
        guard (useCases.location.lastKnownLocation) != nil else {
            self.state = .error("Your current location is not available.")
            return
        }

        guard let supplier = supplierDetailResponse else {
            self.state = .error("Supplier details not available.")
            return
        }

        let destination = CLLocationCoordinate2D(latitude: supplier.latitude, longitude: supplier.longitude)

        // Use the location service to open directions in Maps
        useCases.location.openDirections(to: destination, destinationName: supplier.business_name)
    }
    
    public func isFormValid(step: Int?) -> Bool {
        true
    }
}
