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
import PhotosUI // For PHPickerConfiguration
import UIKit // For UIImagePickerController and UIImage

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
                case .success(let product): // Renamed 'supplier' to 'product' for clarity
                    // MARK: - Image Viewer Section
                    _ProductImageViewer(
                        selectedImages: $viewModel.selectedImages,
                        removeSelectedImage: viewModel.removeSelectedImage,
                        isCreateProduct: viewModel.isCreateProduct,
                        showCameraPicker: $viewModel.showCameraPicker,
                        showImagePicker: $viewModel.showImagePicker
                    )
                    .padding(.vertical, 8) // Apply original padding here
                    
                    // MARK: - Product Details Section
                    if viewModel.isCreateProduct {
                        _ProductCreationForm(
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
                            onMapTapped: handleMapTap // Pass the new map tap handler
                        )
                    } else {
                        // Display actual product details for viewing
                        Text("Product Name: \(viewModel.title)")
                            .font(.title2)
                        Text("Description: \(viewModel.description)") // Assuming description holds the main text
                            .font(.body)
                        // Add more product details here from 'product' if applicable to both states
                    }
                    // Added padding previously inside the success case's VStack
                    // This padding now applies to the content within the success state directly.
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
                viewModel.productDetail() // Fetch product details including images
            } else {
                // For creation, initialize chosenTags from any initial data or keep empty
                // viewModel.chosenTags = viewModel.initialTagsForCreation // Example if you have initial tags
            }
            Task {
                await viewModel.requestLocationAuthorization()
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
                            // For now, only image upload is explicitly defined, need to add product creation logic
                            if viewModel.isFormValid(step: 0) {
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
        let cameraDistance = radius * 4.5
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

// MARK: - Helper Subviews for ProductDetailsView

private struct _ProductImageViewer: View {
    @Binding var selectedImages: [UIImage]
    let removeSelectedImage: (Int) -> Void
    let isCreateProduct: Bool
    @Binding var showCameraPicker: Bool
    @Binding var showImagePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Product Images")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Display existing product images (from URLs)
                    //                                ForEach(product.product_images ?? [], id: \.self) { url in
                    //                                    // AsyncImage is used for loading images from URLs
                    //                                    AsyncImage(url: url) { image in
                    //                                        image.resizable().scaledToFill()
                    //                                    } placeholder: {
                    //                                        ProgressView()
                    //                                    }
                    //                                    .frame(width: 100, height: 100)
                    //                                    .cornerRadius(8)
                    //                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    //                                }
                    
                    // Display newly selected images (from UIImage)
                    ForEach(0..<selectedImages.count, id: \.self) { index in
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    removeSelectedImage(index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .background(Circle().fill(.white))
                                        .padding(4)
                                }
                            }
                    }
                    
                    // Add buttons for image selection/capture (only if creating/editing)
                    if isCreateProduct {
                        VStack {
                            Button {
                                showCameraPicker = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .frame(width: 100, height: 45)
                                    .background(Assets.theme.primary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            Text("Camera")
                                .font(.caption)
                            
                            Button {
                                showImagePicker = true
                            } label: {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title)
                                    .frame(width: 100, height: 45)
                                    .background(Assets.theme.primary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            Text("Upload File")
                                .font(.caption)
                        }
                        .frame(width: 100, height: 200)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct _ProductCreationForm: View {
    @Binding var title: String
    @Binding var description: String
    let validationErrors: [String: String]
    @Binding var chosenTags: [String]
    let removeChosenTag: (String) -> Void
    let detectedTags: [String]
    @Binding var service_radius: CLLocationDistance
    @Binding var mapCameraPosition: MapCameraPosition
    let lastKnownLocation: CLLocation?
    let isAuthorized: Bool
    @Binding var showMultiTagPicker: Bool
    let updateMapCameraPosition: (CLLocationDistance, CLLocation?) -> Void // Closure for map update logic
    @Binding var productMarkerLocation: CLLocationCoordinate2D? // New binding for the product marker
    let onMapTapped: (CLLocationCoordinate2D) -> Void // New closure for map tap handling
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Input fields for creating/editing products
            PrimaryTextInput(label: "Product Name",
                             placeholder: "e.g. Handmade Soap",
                             text: $title,
                             errorMessage: validationErrors["title"]
            )
            PrimaryTextInput(label: "Description",
                             placeholder: "Describe your product",
                             text: $description,
                             errorMessage: validationErrors["description"]
            )
            
            // Tag Picker for product description/tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags") // Label for the tag picker
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Assets.theme.secondaryText)
                
                // Display chosen tags as removable chips
                if !chosenTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(chosenTags, id: \.self) { tag in
                                TagChip(tag: tag) {
                                    removeChosenTag(tag)
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
                .accentColor(Assets.theme.secondaryText)
                
                // Display validation error for tags
                if let errorMessage = validationErrors["chosenTags"] {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal) // Apply padding to the whole tag picker section
            
            VStack(alignment: .leading, spacing: 8) {
                Text("SERVICE RADIUS: \(Int(service_radius / 1000)) km")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Assets.theme.secondaryText)
                
                Slider(value: $service_radius, in: 100...50000, step: 50) {
                    Text("Service Radius")
                } minimumValueLabel: {
                    Text("0.1km")
                } maximumValueLabel: {
                    Text("50km")
                }
                .tint(Assets.theme.primary) // Apply accent color to the slider
                
                if let errorMessage = validationErrors["service_radius"] {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 20) { // This VStack contains the Map and Slider
                // The Visual Map
                MapReader { proxy in
                    Map(position: $mapCameraPosition) {
                        // Add a circle overlay for the service radius
                        if let markerLocation = productMarkerLocation {
                            Marker("Product Location", coordinate: markerLocation)
                            MapCircle(center: markerLocation, radius: service_radius)
                                .stroke(Assets.theme.primaryAccent, lineWidth: 2)
                                .foregroundStyle(Assets.theme.primaryAccent.opacity(0.1))
                        }
                        if let location = lastKnownLocation {
                            MapCircle(center: location.coordinate, radius: service_radius)
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
                                    onMapTapped(coordinate)
                                    print("Successfully tapped coordinate: \(coordinate.latitude), \(coordinate.longitude)")
                                } else {
                                    print("Failed to convert screen point to coordinate.")
                                }
                            }
                    )
                }
                
                // Display error message from validationErrors or location feedback
                if let errorMessage = validationErrors["location"] {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if !isAuthorized {
                    Text("Please enable location services in Settings to pinpoint your service location.")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if lastKnownLocation == nil {
                    Text("Getting your current location...")
                        .font(.caption2)
                        .foregroundColor(Assets.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } // End of VStack containing Map and Slider
            .onChange(of: service_radius) {
                updateMapCameraPosition(service_radius, lastKnownLocation)
            }
            .onChange(of: lastKnownLocation) {
                updateMapCameraPosition(service_radius, lastKnownLocation)
            }
            .onAppear {
                // Set initial camera position if location is already known on appear
                updateMapCameraPosition(service_radius, lastKnownLocation)
            }
        }
        .padding() // Apply padding to the whole creation form section
    }
}

// MARK: - UIViewControllerRepresentable Wrappers for Image Picking

/// A UIViewControllerRepresentable for `PHPickerViewController` to select images from the photo library.
private struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImages: [UIImage] // Directly binds to the ViewModel's selectedImages
    var allowsMultipleSelection: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = allowsMultipleSelection ? 0 : 1 // 0 means unlimited
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else { return }
            
            let dispatchGroup = DispatchGroup()
            var newImages: [UIImage] = []
            
            for result in results {
                dispatchGroup.enter()
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let image = image as? UIImage {
                            newImages.append(image)
                        } else if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // Append new images to the bound array
                self.parent.selectedImages.append(contentsOf: newImages)
            }
        }
    }
}

/// A UIViewControllerRepresentable for `UIImagePickerController` to capture images using the camera.
private struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: UIImage? // Only one image can be captured
    var sourceType: UIImagePickerController.SourceType = .camera
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.presentationMode.wrappedValue.dismiss()
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Helper Views
private struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(tag)
                .font(.subheadline)
                .foregroundColor(Assets.theme.primary)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Assets.theme.primary.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Assets.theme.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - New Multi-Selection Tag Picker View
struct MultiTagPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    let availableTags: [String]
    @Binding var chosenTags: [String]
    let theme: Theme // Use the AppTheme to access colors
    
    // Internal state to hold selections before confirming
    @State private var internalSelectedTags: Set<String>
    
    init(availableTags: [String], chosenTags: Binding<[String]>, theme: Theme) {
        self.availableTags = availableTags
        self._chosenTags = chosenTags
        self.theme = theme
        _internalSelectedTags = State(initialValue: Set(chosenTags.wrappedValue))
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableTags, id: \.self) { tag in
                    Button {
                        if internalSelectedTags.contains(tag) {
                            internalSelectedTags.remove(tag)
                        } else {
                            internalSelectedTags.insert(tag)
                        }
                    } label: {
                        HStack {
                            Text(tag)
                                .foregroundColor(theme.secondaryText)
                            Spacer()
                            if internalSelectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .accentColor(theme.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        chosenTags = Array(internalSelectedTags).sorted()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .accentColor(theme.primary)
                }
            }
        }
    }
}

