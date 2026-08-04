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

public nonisolated struct ProductDetailsModel: Sendable, Equatable, Encodable, Decodable {
    var title: String = ""
    var givenTags: [String] = []
    var selectedTags: [String] = []
}

@MainActor
public final class ProductDetailsViewModel: ProductDetailsViewModelProtocol {
    @Published public private(set) var state: ViewState<ProductDetailsModel> = .success(.init())
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public private(set) var supplierDetailResponse: SupplierDetailResponse?
    
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    @Published public private(set) var isCreateProduct: Bool
    @Published public var productImages: [URL] = []
    @Published public var selectedImages: [UIImage] = []
    @Published public var showImagePicker: Bool = false
    @Published public var showCameraPicker: Bool = false
    
    @Published public var detectedTags: [String] = []
    
    public var productURL: URL?
    private let product_id: String?
    
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
    
    public func handleImageSelection(images: [UIImage]) {
        if images.isEmpty {
            return // No new images to process
        }
        state = .loading // Indicate loading for the classification process
        Task { @MainActor in // Ensure UI updates happen on the main actor
            do {
                let classification = try await useCases.products.classify(images)
                state = .success(.init(title: classification.title, givenTags: classification.tags))
            } catch {
                print("Image classification during selection failed: \(error.localizedDescription)")
                state = .error(error.localizedDescription)
            }
        }
    }
    
    public func uploadImages() async {
        
    }
    
    public func removeSelectedImage(at index: Int) {
        selectedImages.remove(at: index)
    }
}
