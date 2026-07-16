//
//  DashboardView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import SwiftUI
import CommunityCore
import MapKit
import CoreLocation

enum FeedCategory: String, CaseIterable {
    case events, services, products
    
    var display: (text: String, icon: String) {
        switch self {
        case .events: return ("Events", "calendar")
        case .services: return ("Services", "hammer.fill")
        case .products: return ("Products", "cart.fill")
        }
    }
}

enum MatchTab: String, CaseIterable, Identifiable {
    case upcoming = "Upcoming"
    case history = "History"
    var id: String { self.rawValue }
}

enum ServiceTab: String, CaseIterable, Identifiable {
    case map = "Map"
    case list = "List"
    var id: String { self.rawValue }
}

struct DashboardView<T: DashboardViewModelProtocol>: View {
    @StateObject private var viewModel: T
    @State private var selectedCategory: FeedCategory = .events
    @State private var selectedEventTab: MatchTab = .upcoming
    @State private var selectedServiceTab: ServiceTab = .map
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    public init(viewModel: T) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            // Main VStack to organize the CategoryPicker and the content area
            VStack(spacing: 0) {
                CategoryPicker(
                    options: FeedCategory.allCases,
                    selection: $selectedCategory
                ) { category in
                    category.display
                }
                .padding(.horizontal) // Apply horizontal padding to the picker
                .padding(.bottom, 16) // Spacing below the picker
                .background(Assets.theme.surfaceBackground)
                
                // Conditional content based on selectedCategory
                if selectedCategory == .services {
                    // For services, the map should take remaining space directly
                    DashboardContent(
                        viewModel: viewModel,
                        selectedCategory: $selectedCategory,
                        selectedEventTab: $selectedEventTab,
                        selectedServiceTab: $selectedServiceTab,
                        mapCameraPosition: $mapCameraPosition
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow content to fill
                    .background(Assets.theme.surfaceBackground)
                    .cornerRadius(10)
                    .padding(.horizontal) // Horizontal padding for this block
                } else {
                    // For other categories, use a ScrollView
                    ScrollView {
                        // This VStack provides the consistent spacing and styling for scrollable content
                        VStack(spacing: 16) {
                            DashboardContent(
                                viewModel: viewModel,
                                selectedCategory: $selectedCategory,
                                selectedEventTab: $selectedEventTab,
                                selectedServiceTab: $selectedServiceTab,
                                mapCameraPosition: $mapCameraPosition
                            )
                        }
                        .padding() // Inner padding for the scrollable content block
                        .background(Assets.theme.surfaceBackground)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal) // Horizontal padding for the scroll view itself
                }
            }
            .background(Color.clear.ignoresSafeArea()) // Overall background for the NavigationStack content
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        handleCreateButtonTapped()
                    } label: {
                        Label("Create", systemImage: "plus.circle.fill")
                    }
                }
            }
            .onAppear(perform: handleOnAppear)
            .onChange(of: selectedCategory, handleCategoryChange)
        }
    }
    
    // MARK: - Private Helper Methods for Actions
    private func handleCreateButtonTapped() {
        switch selectedCategory {
        case .events:
            viewModel.createMatchTapped()
        case .services:
            viewModel.createSupplierTapped()
        case .products:
            // viewModel.loadProducts()
            break
        }
    }
    
    private func handleOnAppear() {
        Task {
            await viewModel.requestLocationAuthorization()
        }
        
        switch selectedCategory {
        case .events:
            viewModel.matchFeed()
        case .services:
            viewModel.nearbySuppliers()
        case .products:
            // viewModel.loadProducts()
            break
        }
    }
    
    private func handleCategoryChange() {
        switch selectedCategory {
        case .events:
            viewModel.matchFeed()
        case .services:
            viewModel.nearbySuppliers()
        case .products:
            // viewModel.loadProducts()
            break
        }
    }
}

// MARK: - Helper Views for Dashboard Content
/// A private helper view to encapsulate the main content driven by `viewModel.state`.
private struct DashboardContent<T: DashboardViewModelProtocol>: View {
    @ObservedObject var viewModel: T // Use @ObservedObject for child views observing a parent's StateObject
    @Binding var selectedCategory: FeedCategory
    @Binding var selectedEventTab: MatchTab
    @Binding var selectedServiceTab: ServiceTab
    @Binding var mapCameraPosition: MapCameraPosition
    
    var body: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading matches...")
                .padding()
        case .success:
            // Further extract the success state content based on selectedCategory
            DashboardSuccessContent(
                viewModel: viewModel,
                selectedCategory: $selectedCategory,
                selectedEventTab: $selectedEventTab,
                selectedServiceTab: $selectedServiceTab,
                mapCameraPosition: $mapCameraPosition
            )
        case .error(let message):
            Text("Error loading \(message)")
                .foregroundColor(.red)
                .padding()
        }
    }
}

/// A private helper view to encapsulate the content when `viewModel.state` is `.success`.
private struct DashboardSuccessContent<T: DashboardViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @Binding var selectedCategory: FeedCategory
    @Binding var selectedEventTab: MatchTab
    @Binding var selectedServiceTab: ServiceTab
    @Binding var mapCameraPosition: MapCameraPosition
    
    var body: some View {
        switch selectedCategory {
        case .events:
            EventFeedContent(viewModel: viewModel, selectedTab: $selectedEventTab)
        case .services:
            ServiceFeedContent(viewModel: viewModel, selectedTab: $selectedServiceTab, mapCameraPosition: $mapCameraPosition)
        case .products:
            Label("Coming soon", systemImage: "star.fill")
        }
    }
}

/// A private helper view for displaying event-related content.
private struct EventFeedContent<T: DashboardViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @Binding var selectedTab: MatchTab
    
    var body: some View {
        VStack(spacing: 16) {
            Picker("Match Type", selection: $selectedTab) {
                ForEach(MatchTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            let matchesToShow = selectedTab == .upcoming ? viewModel.dashboardModel.upcomingMatches : viewModel.dashboardModel.historyMatches
            
            if matchesToShow.isEmpty {
                Text(selectedTab == .upcoming ?
                     "No upcoming matches found. Create one to get started!" :
                        "No past matches found.")
                .font(.headline)
                .foregroundColor(Assets.theme.secondaryText)
                .padding()
            } else {
                ForEach(matchesToShow, id: \.match_id) { match in
                    MatchFeedItemView(match: match)
                }
            }
        }
    }
}

/// A private helper view for displaying service-related content, including the map.
private struct ServiceFeedContent<T: DashboardViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @Binding var selectedTab: ServiceTab
    @Binding var mapCameraPosition: MapCameraPosition
    
    var body: some View {
        
        VStack(spacing: 16) {
            Picker("Service view", selection: $selectedTab) {
                ForEach(ServiceTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 10)
            if selectedTab == .map {
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
            } else {
                ForEach(viewModel.dashboardModel.suppliers, id: \.id) { supplier in
                    SupplierFeedItemView(supplier: supplier)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: selectedTab == .map ? .infinity : .leastNonzeroMagnitude)
    }
}
