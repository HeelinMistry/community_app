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
public protocol ProductDetailsViewModelProtocol: ValidatableViewModel where DataType == ProductDetailsModel {
//    var supplierDetailResponse: SupplierDetailResponse? { get }
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    var productURL: URL? { get }
    var isCreateProduct: Bool { get }

    // MARK: - Image Handling Properties
    var productImages: [URL] { get } // Existing images for the product, fetched from backend
    var selectedImages: [UIImage] { get set } // Images selected/captured by the user, pending upload
    var showImagePicker: Bool { get set } // Controls presentation of Photo Library picker
    var showCameraPicker: Bool { get set } // Controls presentation of Camera picker

    func productDetail()
    func requestLocationAuthorization() async

    // MARK: - Image Handling Methods
    func handleImageSelection(images: [UIImage]) // Called when images are selected from picker or camera
    func uploadImages() async // Method to upload the selectedImages
    func removeSelectedImage(at index: Int) // Method to remove a selected image from selectedImages
}
