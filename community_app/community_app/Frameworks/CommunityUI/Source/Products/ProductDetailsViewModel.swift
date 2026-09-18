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
    @Published public private(set) var state: ViewState<ProductDetailResponse?> = .success(nil)
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public var productMarkerLocation: CLLocationCoordinate2D?
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    @Published public var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -25.86, longitude: 28.18), // Default South Africa location
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    @Published public var service_radius: Double = 5000.0 {
        didSet {
            productMarkerLocation = nil
        }
    }
    
    @Published public private(set) var isCreateProduct: Bool
    @Published public var productImages: [URL] = []
    @Published public var selectedImages: [UIImage] = []
    @Published public var showImagePicker: Bool = false
    @Published public var showCameraPicker: Bool = false
    
    @Published public var title: String = ""
    @Published public var description: String = ""
    @Published public var detectedTags: [String] = []
    @Published public var chosenTags: [String] = []
    
    public var productURL: URL?
    private var product_id: String? {
        didSet {
            isCreateProduct = product_id == nil
        }
    }
    
    private let router: NavigationRouter
    private let useCases: any ProductUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        useCases: any ProductUseCasesProvider,
        router: NavigationRouter,
        product_id: String?
    ) {
        self.useCases = useCases
        self.router = router
        self.product_id = product_id
        self.isCreateProduct = product_id == nil
        // Guard against nil product_id for URL construction, though force unwrap implies it's always valid
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
    
    public func productDetail() async {
        state = .loading
        do {
            guard let product_id else { return }
            let product = try await useCases.products.selectedProduct(.init(product_id))
            for image_url in product.image_urls {
                productImages.append( try await useCases.products.imageDownloadable(url: image_url))
            }
            state = .success(product)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    public func requestLocationAuthorization() async {
        do {
            try await useCases.location.requestLocationAuthorization()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    public func isFormValid(step: Int? = nil) -> Bool {
        incompleteForm()
        return validationErrors.isEmpty
    }
    
    public func handleImageSelection(images: [UIImage]) {
        if images.isEmpty {
            return // No new images to process
        }
        state = .loading // Indicate loading for the classification process
        Task { @MainActor in // Ensure UI updates happen on the main actor
            do {
                let classification = try await useCases.products.classify(images)
                detectedTags = classification.tags
                state = .success(nil)
            } catch {
                print("Image classification during selection failed: \(error.localizedDescription)")
                state = .error(error.localizedDescription)
            }
        }
    }
    
    public func advertise() async {
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                // Assuming CreateSupplierRequest expects service_radius in kilometers (based on initial 5.1 value)
                let serviceRadiusInKilometers = service_radius / 1000.0
                
                guard let productMarkerLocation else {
                    return
                }
                
                let request = AdvertiseProductRequest(
                    title: title,
                    description: description, // Changed from hardcoded "test" to use the ViewModel's property
                    tags: chosenTags,
                    latitude: productMarkerLocation.latitude,
                    longitude: productMarkerLocation.longitude,
                    service_radius: serviceRadiusInKilometers
                )
                let response: AdvertiseProductResponse = try await useCases.products.advertise(request)
                _ = try await useCases.products.link(productId: response.product_id, images: selectedImages)
                self.product_id = response.product_id
                if !Task.isCancelled {
                    self.state = .success(nil)
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                    self.validationErrors["general"] = "Failed to create match: \(error.localizedDescription)"
                }
            }
        }
    }
    
    public func removeSelectedImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    public func removeChosenTag(_ tag: String) {
        if let index = chosenTags.firstIndex(of: tag) {
            _ = chosenTags.remove(at: index)
        }
    }
    
    private func incompleteForm() {
        var errors: [String: String] = [:]
        if title.isEmpty { errors["title"] = "Title is required" }
        if description.isEmpty { errors["description"] = "Description is required" }
        if productMarkerLocation == nil { errors["location"] = "Location is required" }
        if chosenTags.isEmpty { errors["chosenTags"] = "Tags are required" }
        self.validationErrors = errors
    }
}
