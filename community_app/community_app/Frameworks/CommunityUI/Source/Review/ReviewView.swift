//
//  ReviewView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/09/26.
//

import SwiftUI
import CommunityCore
import Combine
import MapKit

public struct ReviewView<T: ReviewViewModelProtocol>: View {
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
            PrimaryButton("Commit") {
                if viewModel.isFormValid(step: currentStep) {
                    viewModel.review()
                }
            }
            .disabled(viewModel.state.isLoading)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Extracted Step Views

private struct StepOneInputsView<T: ReviewViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @EnvironmentObject private var router: NavigationRouter
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 20) {
            PrimaryTextInput(label: "Comment (Optional)",
                             placeholder: "You can be honest this is anonymous",
                             text: $viewModel.comment
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
        } 
    }
    
}
