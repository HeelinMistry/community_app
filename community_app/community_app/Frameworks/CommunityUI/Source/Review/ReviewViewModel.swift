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
    
    var selectedImages: [UIImage] { get set } // Images selected/captured by the user, pending upload
    var showImagePicker: Bool { get set } // Controls presentation of Photo Library picker
    var showCameraPicker: Bool { get set } // Controls presentation of Camera picker
    
    func requestLocationAuthorization() async
    func review()
    func removeSelectedImage(at index: Int) // Method to remove a selected image from selectedImages
    func handleImageSelection(images: [UIImage]) // Called when images are selected from picker or camera
}

@MainActor
public final class ReviewViewModel: ReviewViewModelProtocol {
    @Published public private(set) var state: ViewState<CreateReviewResponse> = .idle
    @Published public var validationErrors: [String: String] = [:]
    
    @Published public var selectedImages: [UIImage] = []
    @Published public var showImagePicker: Bool = false
    @Published public var showCameraPicker: Bool = false
    
    @Published public var comment = ""
    
    @Published public private(set) var lastKnownLocation: CLLocation?
    @Published public private(set) var isAuthorized: Bool
    
    private let id: String
    private var cancellables = Set<AnyCancellable>()
    
    public func isFormValid(step: Int? = nil) -> Bool {
        validationErrors = [:]
        return validationErrors.isEmpty
    }
    
    private let router: NavigationRouter
    private let useCases: any ReviewUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    
    public init(
        useCases: any ReviewUseCasesProvider,
        router: NavigationRouter,
        id: String
    ) {
        self.useCases = useCases
        self.router = router
        self.id = id
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
    
    public func handleImageSelection(images: [UIImage]) {
        if images.isEmpty {
            return // No new images to process
        }
    }
    
    public func removeSelectedImage(at index: Int) {
        selectedImages.remove(at: index)
    }
    
    public func review() {
        fetchTask?.cancel()
        state = .loading
        fetchTask = Task {
            do {
                let request = CreateReviewRequest(
                    id: id,
                    comment: comment,
                    rating: 5.0,
                    latitude: lastKnownLocation?.coordinate.latitude ?? 0,
                    longitude: lastKnownLocation?.coordinate.longitude ?? 0
                )
                let response: CreateReviewResponse = try await useCases.reviews.createProductReview(request)
//                _ = try await useCases.products.link(productId: response.product_id, images: selectedImages)
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
    }
}
