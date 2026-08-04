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
                                ForEach(0..<viewModel.selectedImages.count, id: \.self) { index in
                                    Image(uiImage: viewModel.selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                                        .overlay(alignment: .topTrailing) {
                                            Button {
                                                viewModel.removeSelectedImage(at: index)
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
                                if viewModel.isCreateProduct {
                                    VStack {
                                        Button {
                                            viewModel.showCameraPicker = true
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
                                            viewModel.showImagePicker = true
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
                        .padding(.vertical, 8)
                        
                        // Placeholder for product details. You would replace this with actual product fields
                        Text("Business Name: \(product.title)")
                            .font(.title2)
                        Text("Description: \(product.givenTags.joined(separator: ", "))")
                            .font(.body)
                        // Add more product details here from 'product'
                    }
                    .padding() // Padding around the VStack content for success state

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
        // Add an upload button if there are selected images for a new product
        .toolbar {
            if viewModel.isCreateProduct && !viewModel.selectedImages.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upload Images") {
                        Task {
                            await viewModel.uploadImages()
                        }
                    }
                    .disabled(viewModel.state.isLoading) // Disable during upload
                }
            }
        }
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
