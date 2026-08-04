//
//  ImageClassifier.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/31.
//

import CoreML
import Vision
import UIKit

// MARK: - Prediction Result Model
/// A structure to hold the result of an image classification,
/// including the identifier of the classified object and its confidence score.
public struct ClassificationResult {
    /// The identifier (label) of the classified object.
    public let identifier: String
    /// The confidence score of the classification, ranging from 0.0 to 1.0.
    public let confidence: VNConfidence
}

/// A class to assist in image classification using models
public final class ImageClassifier {
    
    // MARK: - Classification Method
    /// Classifies a given `UIImage` using a Core ML model.
    ///
    /// - Parameter image: The `UIImage` to be classified.
    /// - Returns: An array of `ClassificationResult` objects,
    ///            representing the top classification results with their identifiers and confidence scores.
    /// - Throws: An error if the classification fails, for example,
    ///           due to an invalid image conversion or an issue with the Core ML model.
    public static func classify(image: UIImage) async throws -> [ClassificationResult] {
        // 1. Load the compiled Core ML model
        // Xcode automatically generates the class name based on your imported .mlpackage file
        let config = MLModelConfiguration()
        config.computeUnits = .all // Utilizes CPU, GPU, and Neural Engine seamlessly
        
        let fastViTModel = try FastViTT8F16(configuration: config)
        let visionModel = try VNCoreMLModel(for: fastViTModel.model)
        
        // 2. Create the Vision request
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // 3. Parse classification observations
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let mappedResults = results.prefix(5).map { observation in
                    ClassificationResult(identifier: observation.identifier, confidence: observation.confidence)
                }
            
                continuation.resume(returning: Array(mappedResults))
            }
            
            // Set scaling option to handle image aspect ratios automatically (Center Crop)
            request.imageCropAndScaleOption = .centerCrop
            
            // 4. Convert UIImage to CIImage and perform request
            guard let ciImage = CIImage(image: image) else {
                continuation.resume(throwing: NSError(domain: "ProductClassifier", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UIImage to CIImage conversion."]))
                return
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
