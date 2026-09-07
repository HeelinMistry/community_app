//
//  ProductDetailsView+ImageViewer.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/28.
//

import Foundation
import SwiftUI

extension ProductDetailsView {
    
    public struct ProductImageViewer: View {
        @Binding var selectedImages: [UIImage]
        let removeSelectedImage: (Int) -> Void
        let isCreateProduct: Bool
        @Binding var showCameraPicker: Bool
        @Binding var showImagePicker: Bool
        
        public var body: some View {
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
}
