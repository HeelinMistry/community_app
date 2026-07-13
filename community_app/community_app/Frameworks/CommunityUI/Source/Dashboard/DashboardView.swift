//
//  DashboardView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import SwiftUI
import CommunityCore

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

struct DashboardView<T: DashboardViewModelProtocol>: View {
    @StateObject private var viewModel: T
    @State private var selectedCategory: FeedCategory = .events
    @State private var selectedTab: MatchTab = .upcoming
    
    public init(viewModel: T) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CategoryPicker(
                        options: FeedCategory.allCases,
                        selection: $selectedCategory
                    ) { category in
                        category.display
                    }
                    
                    switch viewModel.state {
                    case .idle, .loading:
                        ProgressView("Loading matches...")
                            .padding()
                    case .success:
                        switch selectedCategory {
                        case .events:
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
                        case .services:
                            Label("Coming soon", systemImage: "star.fill")
                        case .products:
                            
                            Label("Coming soon", systemImage: "star.fill")
                        }
                    case .error(let message):
                        Text("Error loading matches: \(message)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
                .background(Assets.theme.surfaceBackground)
                .cornerRadius(10)
            }
            .padding()
            .background(Color.clear.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        switch selectedCategory {
                        case .events:
                            viewModel.createMatchTapped()
                        case .services:
                            viewModel.createSupplierTapped()
                        case .products:
                            // viewModel.loadProducts()
                            break
                        }
                        
                    } label: {
                        Label("Create", systemImage: "plus.circle.fill")
                    }
                }
            }
            .onAppear {
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
            .onChange(of: selectedCategory) {
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
    }
}
