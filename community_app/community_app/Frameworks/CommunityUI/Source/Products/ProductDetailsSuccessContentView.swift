//
//  ProductDetailsSuccessContentView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/29.
//

import CommunityCore
import SwiftUI
import MapKit

public struct ProductDetailsSuccessContentView<T: ProductDetailsViewModelProtocol>: View {
    let product: ProductDetailResponse
    @ObservedObject var viewModel: T
    @Binding var mapCameraPosition: MapCameraPosition // To allow VM to control map
    
    // Helper function for distance, adapted from MatchDetailsView
    private func formattedDistance(from userLocation: CLLocation, to productCoordinate: CLLocationCoordinate2D) -> String {
        let productLocation = CLLocation(latitude: productCoordinate.latitude, longitude: productCoordinate.longitude)
        let distanceInMeters = userLocation.distance(from: productLocation)
        let distanceMeasurement = Measurement(value: distanceInMeters, unit: UnitLength.kilometers)
        
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        
        return formatter.string(from: distanceMeasurement)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Image Carousel
            if !product.image_urls.isEmpty {
                TabView {
                    ForEach(product.image_urls, id: \.self) { imageUrlString in
                        AsyncImage(url: URL(string: imageUrlString)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 300)
                        .cornerRadius(12)
                        .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 300)
                .padding(.bottom, 8)
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Assets.theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
            }
            
            // MARK: - Product Title
            Text(product.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.primaryAccent)
            
            // MARK: - Product Description
            Text(product.description)
                .font(.body)
                .foregroundColor(Assets.theme.secondaryText)
            
            Divider()
            
            // MARK: - Tags Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(Assets.theme.secondaryText)
                
                if !product.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(product.tags, id: \.self) { tag in
                                TagChip(tag: tag, onRemove: {})
                            }
                        }
                    }
                } else {
                    Text("No tags available.")
                        .font(.subheadline)
                        .foregroundColor(Assets.theme.secondaryText.opacity(0.7))
                }
            }
            
            Divider()
            
            // MARK: - Map Location and Service Radius
            VStack(alignment: .leading, spacing: 10) {
                Text("Service Area")
                    .font(.headline)
                    .foregroundColor(Assets.theme.secondaryText)
                
                let productCoordinate = CLLocationCoordinate2D(latitude: product.latitude, longitude: product.longitude)
                Map(position: $mapCameraPosition) {
                    Marker(product.title, coordinate: productCoordinate)
                    MapCircle(center: productCoordinate, radius: product.service_radius * 1000) // service_radius is in KM
                        .stroke(Color.blue.opacity(0.7), lineWidth: 2)
                }
                .frame(height: 250)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onAppear {
                    // Adjust map to show product location and service radius
                    // Using a multiplier to ensure the radius is visible within the map frame
                    let cameraDistance = product.service_radius * 1000 * 3 
                    mapCameraPosition = .camera(MapCamera(centerCoordinate: productCoordinate, distance: cameraDistance))
                }
                
                // Distance from User
                if let userLocation = viewModel.lastKnownLocation {
                    Text("Distance from you: \(formattedDistance(from: userLocation, to: productCoordinate))")
                        .font(.subheadline)
                        .foregroundColor(Assets.theme.secondaryText)
                } else if !viewModel.isAuthorized {
                    Text("Location access denied. Enable in Settings for distance info.")
                        .font(.subheadline)
                        .foregroundColor(.red)
                } else {
                    Text("Getting your location...")
                        .font(.subheadline)
                        .foregroundColor(Assets.theme.secondaryText.opacity(0.7))
                }
                
                // Get Directions button
                Button {
                    let placemark = MKPlacemark(coordinate: productCoordinate)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = product.title
                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                } label: {
                    Label("Get Directions", systemImage: "car.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Assets.theme.primaryAccent)
                .disabled(viewModel.lastKnownLocation == nil || !viewModel.isAuthorized)
                .padding(.top, 8)
            }
            
            Divider()
            
            // MARK: - Status Indicators
            VStack(alignment: .leading, spacing: 8) {
                if product.is_creator {
                    Label("You are the Creator", systemImage: "star.fill")
                        .font(.body)
                        .foregroundColor(Assets.theme.primaryAccent)
                }
                
                Label(product.is_available ? "Available" : "Not Available",
                      systemImage: product.is_available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.body)
                .foregroundColor(product.is_available ? .green : .red)
            }
            .padding(.vertical, 4)
            
            Divider()
            
            // MARK: - Action Buttons
            HStack {
                if product.is_creator {
                    Button {
                        // Action to edit product (e.g., navigate to an edit screen)
                        print("Edit Product Tapped")
                    } label: {
                        Label("Edit Product", systemImage: "pencil.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Assets.theme.primaryAccent)
                }
                
                // Share product using its ID
                ShareLink(item: URL(string: "community-app://com.mistcreation.community-app/product/\(product.id)")!) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(Assets.theme.secondaryText)
            }
            .padding(.top, 8)
        }
    }
}
