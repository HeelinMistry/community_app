//
//  ProductCreationForm.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/28.
//

import SwiftUI
import MapKit

public struct ProductCreationForm: View {
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
    let hasSelectedImages: Bool // New property to determine if images are selected
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Input fields for creating/editing products
            PrimaryTextInput(label: "Product Name",
                             placeholder: "e.g. Handmade Soap",
                             text: $title,
                             errorMessage: validationErrors["title"]
            )
            .colorMultiply(!hasSelectedImages ? .gray : .white)
            .disabled(!hasSelectedImages)
            
            PrimaryTextInput(label: "Description",
                             placeholder: "Describe your product",
                             text: $description,
                             errorMessage: validationErrors["description"]
            )
            .colorMultiply(!hasSelectedImages ? .gray : .white)
            .disabled(!hasSelectedImages)
            
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
            .padding(.horizontal)
            .colorMultiply(!hasSelectedImages ? .gray : .white)
            .disabled(!hasSelectedImages)
            
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
            }
            .padding(.horizontal)
            .colorMultiply(!hasSelectedImages ? .gray : .white)
            .disabled(!hasSelectedImages)
            
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
            .colorMultiply(!hasSelectedImages ? .gray : .white)
            .disabled(!hasSelectedImages)
        }
        .padding() // Apply padding to the whole creation form section
    }
}
