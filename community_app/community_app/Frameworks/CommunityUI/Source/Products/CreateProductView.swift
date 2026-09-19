//
//  CreateProductView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/09/18.
//

import SwiftUI
import CommunityCore
import Combine
import MapKit

public struct CreateProductView<T: CreateProductViewModelProtocol>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T
    @State private var currentStep = 1
    
    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Assets.theme.inputBackground.ignoresSafeArea()
                VStack {
                    // Progress Indicator
                    ProgressView(value: Double(currentStep), total: 3)
                        .padding(.horizontal, 30)
                        .background(Assets.theme.primaryAccent)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if currentStep == 1 {
                                StepOneInputsView(viewModel: viewModel)
                            } else if currentStep == 2 {
                                StepTwoInputsView(viewModel: viewModel)
                            } else {
                                StepThreeInputsView(viewModel: viewModel)
                            }
                        }
                        .padding(30)
                    }
                    
                    navigationButtons
                        .padding()
                }
            }
            .padding(30)
            .navigationTitle("Provide Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { router.sheet = nil }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.requestLocationAuthorization()
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 1 {
                Button("Back") { currentStep -= 1 }
                    .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep < 3 {
                PrimaryButton("Next") {
                    if viewModel.isFormValid(step: currentStep) {
                        currentStep += 1
                    }
                }
            } else {
                PrimaryButton("Finish & Create") {
                    if viewModel.isFormValid(step: currentStep) {
                        viewModel.advertise()
                    }
                }
                .disabled(viewModel.state.isLoading)
            }
        }
        .padding(.horizontal, 30)
    }
}

private struct StepOneInputsView<T: CreateProductViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @EnvironmentObject private var router: NavigationRouter
    
    var body: some View {
        VStack(spacing: 20) {
            PrimaryTextInput(label: "Product Name",
                             placeholder: "e.g. Handmade Soap",
                             text: $viewModel.title,
                             errorMessage: viewModel.validationErrors["title"]
            )
            .colorMultiply(!viewModel.hasSelectedImages ? .gray : .white)
            
            PrimaryTextInput(label: "Description",
                             placeholder: "Describe your product",
                             text: $viewModel.description,
                             errorMessage: viewModel.validationErrors["description"]
            )
            .colorMultiply(!viewModel.hasSelectedImages ? .gray : .white)
        }
    }
}

private struct StepTwoInputsView<T: CreateProductViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @EnvironmentObject private var router: NavigationRouter
    @State private var tempCameraImage: UIImage?
    @State private var showMultiTagPicker: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            ProductImageViewer(
                selectedImages: $viewModel.selectedImages,
                removeSelectedImage: viewModel.removeSelectedImage,
                isCreateProduct: true,
                showCameraPicker: $viewModel.showCameraPicker,
                showImagePicker: $viewModel.showImagePicker
            )
            .padding(.vertical, 8)
            
            Text("Tags") // Label for the tag picker
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.secondaryText)
            
            // Display chosen tags as removable chips
            if !viewModel.chosenTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack {
                        ForEach(viewModel.chosenTags, id: \.self) { tag in
                            TagChip(tag: tag) {
                                viewModel.removeChosenTag(tag)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                // Placeholder if no tags are chosen
                Text("No tags selected. Add some!")
                    .font(.subheadline)
                    .foregroundColor(Assets.theme.secondaryText.opacity(0.7))
                    .padding(.vertical, 4)
            }
            
            // Button to open multi-selection tag picker
            Button {
                showMultiTagPicker = true
            } label: {
                HStack {
                    Text("Add/Edit Tags")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Assets.theme.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1) // Default styling
                )
            }
            .disabled(!viewModel.hasSelectedImages)
            .accentColor(Assets.theme.secondaryText)
            
            // Display validation error for tags
            if let errorMessage = viewModel.validationErrors["chosenTags"] {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal)
        .colorMultiply(!viewModel.hasSelectedImages ? .gray : .white)
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
    }
}

private struct StepThreeInputsView<T: CreateProductViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @EnvironmentObject private var router: NavigationRouter
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SERVICE RADIUS: \(Int(viewModel.service_radius / 1000)) km")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.secondaryText)
            
            Slider(value: $viewModel.service_radius, in: 100...50000, step: 50) {
                Text("Service Radius")
            } minimumValueLabel: {
                Text("0.1km")
            } maximumValueLabel: {
                Text("50km")
            }
            .tint(Assets.theme.primary) // Apply accent color to the slider
        }
        .padding(.horizontal)
        .colorMultiply(!viewModel.hasSelectedImages ? .gray : .white)
        .disabled(!viewModel.hasSelectedImages)
        
        VStack(spacing: 20) { // This VStack contains the Map and Slider
            // The Visual Map
            MapReader { proxy in
                Map(position: $mapCameraPosition) {
                    // Add a circle overlay for the service radius
                    if let markerLocation = viewModel.productMarkerLocation {
                        Marker("Product Location", coordinate: markerLocation)
                        MapCircle(center: markerLocation, radius: viewModel.service_radius)
                            .stroke(Assets.theme.primaryAccent, lineWidth: 2)
                            .foregroundStyle(Assets.theme.primaryAccent.opacity(0.1))
                    }
                    if let location = viewModel.lastKnownLocation {
                        MapCircle(center: location.coordinate, radius: viewModel.service_radius)
                            .stroke(Assets.theme.secondary, lineWidth: 1)
                            .foregroundStyle(Assets.theme.primaryAccent.opacity(0.2))
                    }
                    
                }
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                // Use SpatialTapGesture to intercept taps within the MapReader context
                .simultaneousGesture(
                    SpatialTapGesture(coordinateSpace: .local)
                        .onEnded { value in
                            let screenPoint = value.location
                            
                            // Convert the CGPoint to CLLocationCoordinate2D using MapProxy
                            if let coordinate = proxy.convert(screenPoint, from: .local) {
                                handleMapTap(coordinate: coordinate)
                            } else {
                                print("Failed to convert screen point to coordinate.")
                            }
                        }
                )
            }
            
            // Display error message from validationErrors or location feedback
            if let errorMessage = viewModel.validationErrors["location"] {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else if !viewModel.isAuthorized {
                Text("Please enable location services in Settings to pinpoint your service location.")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else if viewModel.lastKnownLocation == nil {
                Text("Getting your current location...")
                    .font(.caption2)
                    .foregroundColor(Assets.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        } // End of VStack containing Map and Slider
        .onChange(of: viewModel.service_radius) {
            updateMapCameraPosition(radius: viewModel.service_radius, location: viewModel.lastKnownLocation)
        }
        .onChange(of: viewModel.lastKnownLocation) {
            updateMapCameraPosition(radius: viewModel.service_radius, location: viewModel.lastKnownLocation)
        }
        .onAppear {
            // Set initial camera position if location is already known on appear
            updateMapCameraPosition(radius: viewModel.service_radius, location: viewModel.lastKnownLocation)
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
