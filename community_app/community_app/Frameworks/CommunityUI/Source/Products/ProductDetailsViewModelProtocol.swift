//
//  ProductDetailsViewModelProtocol.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/26.
//

import Combine
import CommunityCore
import CoreLocation
import MapKit
import Foundation
import SwiftUI // Import SwiftUI for UIImage

@MainActor
public protocol ProductDetailsViewModelProtocol: ValidatableViewModel where DataType == AdvertiseProductResponse? {
//    var supplierDetailResponse: SupplierDetailResponse? { get }
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    var mapCameraPosition: MapCameraPosition { get set }
    var service_radius: Double { get set }
    var productMarkerLocation: CLLocationCoordinate2D? { get set } 

    var productURL: URL? { get }
    var isCreateProduct: Bool { get }

    // MARK: - Product Details Editable Properties (for create/edit mode)
    var title: String { get set } // Assuming 'title' is editable for product creation
    var description: String { get set } // Assuming 'description' is editable for product creation
    var detectedTags: [String] { get } // The full list of tags available for selection
    var chosenTags: [String] { get set } // The tags selected by the user for the product

    // MARK: - Image Handling Properties
    var productImages: [URL] { get } // Existing images for the product, fetched from backend
    var selectedImages: [UIImage] { get set } // Images selected/captured by the user, pending upload
    var showImagePicker: Bool { get set } // Controls presentation of Photo Library picker
    var showCameraPicker: Bool { get set } // Controls presentation of Camera picker

    func productDetail()
    func requestLocationAuthorization() async

    // MARK: - Image Handling Methods
    func handleImageSelection(images: [UIImage]) // Called when images are selected from picker or camera
    func advertise() async // Method to upload the selectedImages
    func removeSelectedImage(at index: Int) // Method to remove a selected image from selectedImages
    
    // MARK: - Tag Handling Methods
    func removeChosenTag(_ tag: String)
}

