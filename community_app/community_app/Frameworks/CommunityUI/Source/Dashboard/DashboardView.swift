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
    @State private var selectedServiceTab: ServiceTab = .list
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    public init(viewModel: T) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            // Main VStack to organize the CategoryPicker and the content area
            VStack {
                CategoryPicker(
                    options: FeedCategory.allCases,
                    selection: $selectedCategory
                ) { category in
                    category.display
                }
                .background(Assets.theme.surfaceBackground)
                
                VStack(spacing: 16) {
                    DashboardContent(
                        viewModel: viewModel,
                        selectedCategory: $selectedCategory,
                        selectedEventTab: $selectedEventTab,
                        selectedServiceTab: $selectedServiceTab,
                        mapCameraPosition: $mapCameraPosition
                    )
                }
                .padding()
                .background(Assets.theme.surfaceBackground)
                .cornerRadius(15)
                Spacer()
                
            }
            .background(Color.clear.ignoresSafeArea()) // Overall background for the NavigationStack content
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(FeedCategory.allCases, id: \.self) { category in
                            Button {
                                switch category {
                                case .events:
                                    viewModel.createMatchTapped()
                                case .services:
                                    viewModel.createSupplierTapped()
                                case .products:
                                    viewModel.createProductTapped()
                                }
                            } label: {
                                Label(category.display.text, systemImage: category.display.icon)
                            }
                        }
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
    // handleCreateButtonTapped is removed as its logic is now in the Menu items
    
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
            ProgressView("Loading \(selectedCategory.rawValue)...")
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
            Text("Error \(message)")
                .multilineTextAlignment(.center)
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
            EventFeedView(viewModel: viewModel, selectedTab: $selectedEventTab)
        case .services:
            ServiceFeedView(viewModel: viewModel, selectedTab: $selectedServiceTab, mapCameraPosition: $mapCameraPosition)
        case .products:
            Label("Coming soon", systemImage: "star.fill")
        }
    }
}
