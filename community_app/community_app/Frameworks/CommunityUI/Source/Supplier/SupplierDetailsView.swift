//
//  SupplierDetailsView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/24.
//

import SwiftUI
import Foundation
import CommunityCore
import MapKit
import CoreLocation

// MARK: - File-level Helper Functions and Formatters

/// Formats the distance between two CLLocation objects into a user-friendly string.
private func fileFormattedDistance(from userLocation: CLLocation, to targetLocation: CLLocation) -> String {
    let distanceInMeters = userLocation.distance(from: targetLocation)
    let distanceMeasurement = Measurement(value: distanceInMeters, unit: UnitLength.kilometers)

    let formatter = MeasurementFormatter()
    formatter.unitStyle = .long
    formatter.unitOptions = .providedUnit // Use the unit provided (kilometers)
    formatter.numberFormatter.maximumFractionDigits = 1 // One decimal place

    return formatter.string(from: distanceMeasurement)
}

// MARK: - File-level Helper Views (similar to MatchDetailRow)

/// A reusable row view for displaying a labeled detail, similar to MatchDetailRow.
private struct SupplierDetailRow: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(Assets.theme.secondaryText)
            Text(value)
                .font(.title3)
                .foregroundColor(Assets.theme.primaryAccent)
        }
    }
}

/// Content view for a successful supplier details fetch, similar to MatchDetailsSuccessContentView.
private struct SupplierDetailsSuccessContentView<T: SupplierDetailsViewModelProtocol>: View {
    let supplier: SupplierDetailResponse
    @ObservedObject var viewModel: T
    @Binding var mapCameraPosition: MapCameraPosition // State to control the map's camera

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Supplier Overview
            Text(supplier.business_name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.primaryAccent)
                .padding(.bottom, 8)

            SupplierDetailRow(label: "Category", value: supplier.category, systemImage: "tag.fill")
            SupplierDetailRow(label: "Description", value: supplier.description, systemImage: "text.alignleft")

            // MARK: - Distance from User
            if let userLocation = viewModel.lastKnownLocation,
               supplier.latitude != 0.0 || supplier.longitude != 0.0 {
                let supplierCLLocation = CLLocation(latitude: supplier.latitude, longitude: supplier.longitude)
                SupplierDetailRow(label: "Distance from you", value: fileFormattedDistance(from: userLocation, to: supplierCLLocation), systemImage: "figure.walk.circle.fill")
            } else {
                if !viewModel.isAuthorized {
                    Text("Location access denied. Please enable in Settings to see distance.")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.leading)
                } else if viewModel.lastKnownLocation == nil {
                    Text("Getting your location...")
                        .font(.subheadline)
                        .foregroundColor(Assets.theme.secondaryText.opacity(0.7))
                        .padding(.leading)
                }
            }

            SupplierDetailRow(label: "Service Radius", value: "\(Int(supplier.service_radius)) km", systemImage: "point.3.connected.trianglepath.dotted")

            Divider()

            // MARK: - Map View for Location
            VStack(alignment: .leading, spacing: 10) {
                Text("Supplier Location")
                    .font(.headline)
                    .foregroundColor(Assets.theme.secondaryText)

                if supplier.latitude != 0.0 || supplier.longitude != 0.0 {
                    Map(position: $mapCameraPosition) {
                        Marker(supplier.business_name, coordinate: CLLocationCoordinate2D(latitude: supplier.latitude, longitude: supplier.longitude))
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onAppear {
                        // Set the map camera to focus on the supplier's location
                        mapCameraPosition = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: supplier.latitude, longitude: supplier.longitude),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }

                    // Button to get directions using Apple Maps
                    Button {
                        viewModel.showDirectionsOnMap()
                    } label: {
                        Label("Get Directions", systemImage: "car.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Assets.theme.primaryAccent)
                    .disabled(viewModel.lastKnownLocation == nil || supplier.latitude == 0.0 || supplier.longitude == 0.0 || !viewModel.isAuthorized)
                    .padding(.top, 8)

                } else {
                    Text("Location coordinates not available.")
                        .font(.subheadline)
                        .foregroundColor(Assets.theme.secondaryText.opacity(0.7))
                        .padding(.top, 4)
                }
            }

            // MARK: - Share Link
            ShareLink(item: viewModel.supplierURL, subject: Text("Check out this supplier: \(supplier.business_name)!")) {
                Label("Share Supplier", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(Assets.theme.secondaryText)
            .padding(.top, 8)
        }
    }
}

// MARK: - Main SupplierDetailsView

public struct SupplierDetailsView<T: SupplierDetailsViewModelProtocol>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T

    // State to control the map's camera position
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch viewModel.state {
                case .idle:
                    Text("Loading supplier details...")
                        .foregroundColor(Assets.theme.secondaryText)
                case .loading:
                    ProgressView("Loading Supplier Details...")
                        .controlSize(.large)
                case .success(let supplier):
                    SupplierDetailsSuccessContentView(supplier: supplier, viewModel: viewModel, mapCameraPosition: $mapCameraPosition)
                case .error(let message):
                    Text("Error: \(message)")
                        .foregroundColor(.red)
                        .font(.headline)
                        .padding()
                }
            }
            .padding() // Padding around the VStack content
        }
        .navigationTitle("Supplier Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Fetch supplier details and request location authorization when the view appears
            viewModel.supplierDetail()
            Task {
                await viewModel.requestLocationAuthorization()
            }
        }
    }
}
