//
//  CreateSupplierView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/11.
//

import SwiftUI
import CommunityCore
import Combine
import MapKit

public struct CreateSupplierView<T: CreateSupplierViewModelProtocol>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T
    @State private var currentStep = 1
    
    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Assets.theme.inputBackground.ignoresSafeArea()
                VStack {
                    // Progress Indicator
                    ProgressView(value: Double(currentStep), total: 3)
                        .padding(.horizontal, 30)
                        .background(Assets.theme.primaryAccent)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if currentStep == 1 {
                                StepOneInputsView(viewModel: viewModel)
                            }
                        }
                        .padding(30)
                    }
                    
                    navigationButtons
                        .padding()
                }
            }
            .padding(30)
            .navigationTitle("Provide Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { router.sheet = nil }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.requestLocationAuthorization()
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            PrimaryButton("Finish & Create") {
                if viewModel.isFormValid(step: currentStep) {
                    viewModel.create()
                }
            }
            .disabled(viewModel.state.isLoading)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Extracted Step Views

private struct StepOneInputsView<T: CreateSupplierViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @EnvironmentObject private var router: NavigationRouter
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            PrimaryTextInput(label: "Name",
                             placeholder: "e.g. Shoe Cleaning",
                             text: $viewModel.business_name,
                             errorMessage: viewModel.validationErrors["business_name"]
            )
            // MARK: - New Description Input
            PrimaryTextInput(label: "Description",
                             placeholder: "Provide a detailed description of your service.",
                             text: $viewModel.description,
                             errorMessage: viewModel.validationErrors["description"]
            )
            PrimaryPicker(
                label: "Category",
                selection: $viewModel.category,
                options: SupplierCategory.allCases,
                optionLabel: { category in Text(category.localizedName) },
                errorMessage: viewModel.validationErrors["category"]
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("SERVICE RADIUS: \(Int(viewModel.service_radius / 1000)) km")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Assets.theme.secondaryText)
                
                Slider(value: $viewModel.service_radius, in: 100...50000, step: 50) {
                    Text("Service Radius")
                } minimumValueLabel: {
                    Text("0.1km")
                } maximumValueLabel: {
                    Text("50km")
                }
                .tint(Assets.theme.primary) // Apply accent color to the slider
                
                if let errorMessage = viewModel.validationErrors["service_radius"] {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 20) { // This VStack contains the Map and Slider
                // The Visual Map
                Map(position: $viewModel.mapCameraPosition) {
                    UserAnnotation()
                    // Add a circle overlay for the service radius
                    if let location = viewModel.lastKnownLocation {
                        MapCircle(center: location.coordinate, radius: viewModel.service_radius)
                            .stroke(Assets.theme.primaryAccent, lineWidth: 2)
                            .foregroundStyle(Assets.theme.primaryAccent.opacity(0.1))
                    }
                }
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

                // Display error message from validationErrors or location feedback
                if let errorMessage = viewModel.validationErrors["location"] {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if !viewModel.isAuthorized {
                    Text("Please enable location services in Settings to pinpoint your service location.")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if viewModel.lastKnownLocation == nil {
                    Text("Getting your current location...")
                        .font(.caption2)
                        .foregroundColor(Assets.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } // End of VStack containing Map and Slider
            .onChange(of: viewModel.service_radius) {
                updateMapCameraPosition(radius: viewModel.service_radius, location: viewModel.lastKnownLocation)
            }
            .onChange(of: viewModel.lastKnownLocation) {
                updateMapCameraPosition(radius: viewModel.service_radius, location: viewModel.lastKnownLocation)
            }
            .onAppear {
                // Set initial camera position if location is already known on appear
                updateMapCameraPosition(radius: viewModel.service_radius, location: viewModel.lastKnownLocation)
            }
        }
    }

    /// Updates the map's camera position to encompass the service radius around the given location.
    /// - Parameters:
    ///   - radius: The service radius in meters.
    ///   - location: The center location for the service radius.
    private func updateMapCameraPosition(radius: CLLocationDistance, location: CLLocation?) {
        guard let coordinate = location?.coordinate else { return }
        let cameraDistance = radius * 4.5
        viewModel.mapCameraPosition = .camera(MapCamera(centerCoordinate: coordinate, distance: cameraDistance))
    }
}
