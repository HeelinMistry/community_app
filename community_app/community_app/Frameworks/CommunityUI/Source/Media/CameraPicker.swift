//
//  CameraPicker.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/28.
//

import Foundation
import SwiftUI
import UIKit

/// A UIViewControllerRepresentable for `UIImagePickerController` to capture images using the camera.
public struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: UIImage? // Only one image can be captured
    var sourceType: UIImagePickerController.SourceType = .camera
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.presentationMode.wrappedValue.dismiss()
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
