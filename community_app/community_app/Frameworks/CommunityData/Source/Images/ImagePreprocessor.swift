//
//  ImagePreprocessor.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/29.
//

import UIKit

public struct ImagePreprocessor: Sendable {
    
    /// Prepares an image for network upload by compressing and resizing it.
    ///
    /// This method first corrects the image's orientation, then resizes it to fit within a specified maximum dimension
    /// while maintaining its aspect ratio, and finally compresses it as JPEG data.
    ///
    /// - Parameter image: The `UIImage` to be optimized.
    /// - Parameter maxDimension: The maximum desired width or height for the output image. The other dimension will be
    ///                           scaled proportionally. Defaults to 1024.
    /// - Returns: The JPEG compressed image data (with 80% quality), or `nil` if the optimization fails
    ///            (e.g., if the image context cannot be created or the image cannot be converted to data).
    public static func optimizeForUpload(_ image: UIImage, maxDimension: CGFloat = 1024) -> Data? {
        // 1. Correct orientation
        let normalizedImage = image.fixedOrientation()
        
        // 2. Resize maintaining aspect ratio
        let size = normalizedImage.size
        let aspectRatio = size.width / size.height
        
        var targetWidth: CGFloat = maxDimension
        var targetHeight: CGFloat = maxDimension
        
        if aspectRatio > 1 {
            targetHeight = targetWidth / aspectRatio
        } else {
            targetWidth = targetHeight * aspectRatio
        }
        
        let targetSize = CGSize(width: targetWidth, height: targetHeight)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        normalizedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 3. Compress to JPEG (e.g., 80% quality)
        return resizedImage?.jpegData(compressionQuality: 0.8)
    }
}

extension UIImage {
    /// Helper to fix image orientation issues that can arise from camera uploads.
    ///
    /// This method ensures the image is rendered with `.up` orientation,
    /// preventing rotation issues when displaying or processing.
    ///
    /// - Returns: A new `UIImage` instance with corrected orientation, or the original image
    ///            if its orientation is already `.up`.
    public func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}
