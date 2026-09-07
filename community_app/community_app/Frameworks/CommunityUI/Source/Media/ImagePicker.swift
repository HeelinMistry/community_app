//
//  ImagePicker.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/28.
//

import Foundation
import SwiftUI
import UIKit
import PhotosUI

/// A UIViewControllerRepresentable for `PHPickerViewController` to select images from the photo library.
public struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImages: [UIImage] // Directly binds to the ViewModel's selectedImages
    var allowsMultipleSelection: Bool
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = allowsMultipleSelection ? 0 : 1 // 0 means unlimited
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
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
