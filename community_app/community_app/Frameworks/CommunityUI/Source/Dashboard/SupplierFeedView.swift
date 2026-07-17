//
//  SupplierFeedView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/17.
//

import Foundation
import SwiftUI
import MapKit
import CommunityCore

public struct ServiceFeedView<T: DashboardViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @Binding var selectedTab: ServiceTab
    @Binding var mapCameraPosition: MapCameraPosition
    
    public var body: some View {
            Picker("Service view", selection: $selectedTab) {
                ForEach(ServiceTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
//            .padding(.horizontal)
//            .padding(.bottom, 10)
            
            if selectedTab == .map {
                VStack {
                    Map(position: $mapCameraPosition, interactionModes: .all) {
                        UserAnnotation()
                        // Add markers for suppliers
                        ForEach(viewModel.dashboardModel.suppliers, id: \.id) { supplier in
                            if supplier.latitude != 0.0 || supplier.longitude != 0.0 {
                                Marker(
                                    supplier.business_name,
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: supplier.latitude,
                                        longitude: supplier.longitude
                                    )
                                )
                            }
                        }
                    }
                    .mapControls {
                        MapUserLocationButton()
                    }
                    // Removed fixed height, now it will expand within its parent VStack
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow map to take all available space
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onAppear {
                        // Set the initial camera position when the view appears, if still automatic.
                        // This ensures the map centers on the lastKnownLocation or the first supplier.
                        if mapCameraPosition == .automatic {
                            if let userLocation = viewModel.lastKnownLocation {
                                mapCameraPosition = .camera(MapCamera(centerCoordinate: userLocation.coordinate, distance: 10000)) // 10km distance around user
                            } else if let firstSupplier = viewModel.dashboardModel.suppliers.first,
                                      firstSupplier.latitude != 0.0 || firstSupplier.longitude != 0.0 {
                                mapCameraPosition = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: firstSupplier.latitude, longitude: firstSupplier.longitude), distance: 10000)) // 10km distance around first supplier
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.dashboardModel.suppliers, id: \.id) { supplier in
                            SupplierFeedItemView(supplier: supplier)
                        }
                        // Add a Spacer to push the list items to the top if they don't fill the available space.
                        Spacer()
                    }
                }
            }
        // Ensure the VStack fills all available vertical space in both map and list modes.
        // A VStack naturally aligns its content to the top.
    }
}
