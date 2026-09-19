//
//  CreateProductViewModel.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/09/18.
//

import MapKit
import SwiftUI
import Combine
import Foundation
import CommunityCore

@MainActor
public protocol CreateProductViewModelProtocol: ValidatableViewModel {
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    var mapCameraPosition: MapCameraPosition { get set }
    var service_radius: Double { get set }
    var productMarkerLocation: CLLocationCoordinate2D? { get set } 
    
    // MARK: - Product Details Editable Properties (for create/edit mode)
    var title: String { get set } // Assuming 'title' is editable for product creation
    var description: String { get set } // Assuming 'description' is editable for product creation
    var detectedTags: [String] { get } // The full list of tags available for selection
    var chosenTags: [String] { get set } // The tags selected by the user for the product

    // MARK: - Image Handling Properties
    var productImages: [URL] { get } // Existing images for the product, fetched from backend
    var selectedImages: [UIImage] { get set } // Images selected/captured by the user, pending upload
    var hasSelectedImages: Bool { get } 
    var showImagePicker: Bool { get set } // Controls presentation of Photo Library picker
    var showCameraPicker: Bool { get set } // Controls presentation of Camera picker

    func requestLocationAuthorization() async
    
    // MARK: - Image Handling Methods
    func handleImageSelection(images: [UIImage]) // Called when images are selected from picker or camera
    func advertise() // Method to upload the selectedImages
    func removeSelectedImage(at index: Int) // Method to remove a selected image from selectedImages
    
    // MARK: - Tag Handling Methods
    func removeChosenTag(_ tag: String)

}

@MainActor
public final class CreateProductViewModel: CreateProductViewModelProtocol {
    
    @Published public private(set) var state: ViewState<AdvertiseProductResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public var productMarkerLocation: CLLocationCoordinate2D?
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    @Published public var mapCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -25.86, longitude: 28.18), // Default South Africa location
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    @Published public var service_radius: Double = 1000.0 {
        didSet {
            productMarkerLocation = nil
        }
    }
    
    @Published public var productImages: [URL] = []
    @Published public var selectedImages: [UIImage] = []
    @Published public var showImagePicker: Bool = false
    @Published public var showCameraPicker: Bool = false
    
    @Published public var title: String = ""
    @Published public var description: String = ""
    @Published public var detectedTags: [String] = []
    @Published public var chosenTags: [String] = []
    
    private let router: NavigationRouter
    private let useCases: any ProductUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        useCases: any ProductUseCasesProvider,
        router: NavigationRouter) {
        self.useCases = useCases
        self.router = router
        
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
    
    public func requestLocationAuthorization() async {
        do {
            try await useCases.location.requestLocationAuthorization()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    public func isFormValid(step: Int? = nil) -> Bool {
        validationErrors = [:]
        guard let step,
              let validationStep = CreateMatchSteps(rawValue: step) else {
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
    
    public var hasSelectedImages: Bool {
        !selectedImages.isEmpty
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
                state = .idle
            } catch {
                print("Image classification during selection failed: \(error.localizedDescription)")
                state = .error(error.localizedDescription)
            }
        }
    }
    
    public func advertise() {
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
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
                if !Task.isCancelled {
                    self.state = .success(response)
                    NotificationCenter.default.post(name: .productCreated, object: nil)
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
    
    public func removeSelectedImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    public func removeChosenTag(_ tag: String) {
        if let index = chosenTags.firstIndex(of: tag) {
            _ = chosenTags.remove(at: index)
        }
    }
    
    private func incompleteFormStep1() {
        var errors: [String: String] = [:]
        if title.isEmpty { errors["title"] = "Title is required" }
        if description.isEmpty { errors["description"] = "Description is required" }
        self.validationErrors = errors
    }
    
    private func incompleteFormStep2() {
        var errors: [String: String] = [:]
        if chosenTags.isEmpty { errors["chosenTags"] = "Tags are required" }
        self.validationErrors = errors
    }
    
    private func incompleteFormStep3() {
        var errors: [String: String] = [:]
        if productMarkerLocation == nil { errors["location"] = "Location is required" }
        self.validationErrors = errors
    }
}
