//
//  DashboardView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import SwiftUI
import CommunityCore

struct DashboardView<T: DashboardViewModelProtocol>: View {
    @StateObject private var viewModel: T
    
    public init(viewModel: T) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PrimaryText(label: "Welcome to Your Feed!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)
                    
                    VStack(spacing: 16) {
                        switch viewModel.state {
                        case .idle, .loading:
                            ProgressView("Loading matches...")
                                .padding()
                        case .success(let matches):
                            if matches.isEmpty {
                                Text("No matches found. Create one to get started!")
                                    .font(.headline)
                                    .foregroundColor(Assets.theme.secondaryText)
                                    .padding()
                            } else {
                                ForEach(matches, id: \.match_id) { match in
                                    MatchFeedItemView(match: match)
                                }
                            }
                        case .error(let message):
                            Text("Error loading matches: \(message)")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .padding()
                    .background(Assets.theme.inputBackground)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.clear.ignoresSafeArea())
                .navigationTitle("Dashboard")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.createMatchTapped()
                        } label: {
                            Label("Create Match", systemImage: "plus.circle.fill")
                        }
                    }
                }
                .onAppear {
                    viewModel.matchFeed()
                }
                .refreshable {
                    viewModel.matchFeed()
                }
            }
        }
    }
}
