//
//  ProductDetailsView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/26.
//

import SwiftUI
import Foundation
import CommunityCore
import MapKit
import CoreLocation
import PhotosUI 
import UIKit 

// MARK: - Main ProductDetailsView

public struct ProductDetailsView<T: ProductDetailsViewModelProtocol>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T
    
    // State to control the map's camera position
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    // Temporary storage for camera image before passing to VM
    @State private var tempCameraImage: UIImage?
    
    // New state to control the presentation of the multi-tag picker sheet
    @State private var showMultiTagPicker: Bool = false
    
    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch viewModel.state {
                case .idle:
                    Text("Loading product details...")
                        .foregroundColor(Assets.theme.secondaryText)
                case .loading:
                    ProgressView("Loading Product Details...")
                        .controlSize(.large)
                case .success(let product):
                    if viewModel.isCreateProduct {
                        // MARK: - Image Viewer Section (for creation)
                        ProductImageViewer(
                            selectedImages: $viewModel.selectedImages,
                            removeSelectedImage: viewModel.removeSelectedImage,
                            isCreateProduct: viewModel.isCreateProduct,
                            showCameraPicker: $viewModel.showCameraPicker,
                            showImagePicker: $viewModel.showImagePicker
                        )
                        .padding(.vertical, 8) // Apply original padding here
                        
                        // MARK: - Product Creation Form
                        ProductCreationForm(
                            title: $viewModel.title,
                            description: $viewModel.description,
                            validationErrors: viewModel.validationErrors,
                            chosenTags: $viewModel.chosenTags,
                            removeChosenTag: viewModel.removeChosenTag,
                            detectedTags: viewModel.detectedTags,
                            service_radius: $viewModel.service_radius,
                            mapCameraPosition: $viewModel.mapCameraPosition,
                            lastKnownLocation: viewModel.lastKnownLocation,
                            isAuthorized: viewModel.isAuthorized,
                            showMultiTagPicker: $showMultiTagPicker,
                            updateMapCameraPosition: updateMapCameraPosition, // Pass the method as a closure
                            productMarkerLocation: $viewModel.productMarkerLocation, // Pass productMarkerLocation binding
                            onMapTapped: handleMapTap, // Pass the new map tap handler
                            hasSelectedImages: !viewModel.selectedImages.isEmpty // Pass the image selection status
                        )
                    } else {
                        // MARK: - Product Details Section (for viewing existing product)
                        if let product = product {
                            ProductDetailsSuccessContentView(
                                product: product,
                                viewModel: viewModel,
                                mapCameraPosition: $mapCameraPosition
                            )
                        } else {
                            Text("Product details not available.")
                                .foregroundColor(Assets.theme.secondaryText)
                        }
                    }
                case .error(let message):
                    Text("Error: \(message)")
                        .foregroundColor(.red)
                        .font(.headline)
                        .padding()
                }
            }
            .padding() // Padding around the VStack content for all states
        }
        .navigationTitle(viewModel.isCreateProduct ? "Create Product" : "Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !viewModel.isCreateProduct {
                Task {
                    await viewModel.productDetail() // Fetch product details including images
                }
            } else {
                // For creation, initialize chosenTags from any initial data or keep empty
                // viewModel.chosenTags = viewModel.initialTagsForCreation // Example if you have initial tags
            }
            Task {
                await viewModel.requestLocationAuthorization()
            }
        }
        .onChange(of: viewModel.isCreateProduct) { _, newValue in
            if !newValue {
                Task {
                    await viewModel.productDetail() 
                }
            }
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(selectedImages: $viewModel.selectedImages, allowsMultipleSelection: true)
                .onDisappear {
                    // ViewModel's selectedImages is directly updated by ImagePicker.
                    // Call handleImageSelection to process (e.g., validate, resize) them.
                    if !viewModel.selectedImages.isEmpty {
                        viewModel.handleImageSelection(images: viewModel.selectedImages)
                    }
                }
        }
        .sheet(isPresented: $viewModel.showCameraPicker) {
            CameraPicker(selectedImage: $tempCameraImage, sourceType: .camera)
                .onDisappear {
                    if let capturedImage = tempCameraImage {
                        viewModel.handleImageSelection(images: [capturedImage])
                        tempCameraImage = nil // Clear temporary image after processing
                    }
                }
        }
        .sheet(isPresented: $showMultiTagPicker) {
            MultiTagPickerView(
                availableTags: viewModel.detectedTags,
                chosenTags: $viewModel.chosenTags,
                theme: Assets.theme // Pass theme for consistent styling
            )
        }
        // Add an upload button if there are selected images for a new product
        .toolbar {
            if viewModel.isCreateProduct { // Toolbar item should be available if creating/editing generally
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Product") { // Renamed button from "Upload Images" to "Save Product"
                        Task {
                            // Assuming a method like 'saveProduct' or 'createProduct' exists in VM
                            // This would include uploading images and submitting product details
                            // await viewModel.createProduct() // Example
                            print("Save Product button tapped. Chosen tags: \(viewModel.chosenTags)")
                            print("Selected images count: \(viewModel.selectedImages.count)")
                            // For now, only image upload is explicitly defined,
                            if viewModel.isFormValid(step: nil) {
                                await viewModel.advertise()
                            } // If images are part of creation
                        }
                    }
                    .disabled(viewModel.state.isLoading) // Disable during upload/save
                }
            }
        }
    }
    
    /// Updates the map's camera position to encompass the service radius around the given location.
    /// - Parameters:
    ///   - radius: The service radius in meters.
    ///   - location: The center location for the service radius.
    private func updateMapCameraPosition(radius: CLLocationDistance, location: CLLocation?) {
        guard let coordinate = location?.coordinate else { return }
        let cameraDistance = radius * 7
        viewModel.mapCameraPosition = .camera(MapCamera(centerCoordinate: coordinate, distance: cameraDistance))
    }
    
    /// Handles a tap gesture on the map, updating the productMarkerLocation if within the service radius.
    /// - Parameter coordinate: The CLLocationCoordinate2D where the map was tapped.
    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        guard let centerLocation = viewModel.lastKnownLocation else {
            // Cannot determine if tap is within radius without a center location
            // Optionally, show a message to the user or clear the marker
            viewModel.productMarkerLocation = nil
            return
        }
        
        let tappedCLLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = centerLocation.distance(from: tappedCLLocation)
        
        if distance <= viewModel.service_radius {
            viewModel.productMarkerLocation = coordinate
        } else {
            // Tapped outside the service radius.
            // You might want to provide visual feedback or prevent setting the marker.
            // For now, we'll just not update the marker if it's outside.
            print("Tapped outside service radius: \(distance) meters, radius: \(viewModel.service_radius) meters")
        }
    }
}
