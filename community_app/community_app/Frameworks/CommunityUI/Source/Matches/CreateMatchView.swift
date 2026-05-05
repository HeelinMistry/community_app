//
//  CreateMatchView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/01.
//

import SwiftUI
import CommunityCore

private enum Sport: String {
    case soccer
    case padel
}

public struct CreateMatchView<T: CreateMatchViewModelProtocol>: View {
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
                                stepOneInputs // Title, Sport, Location
                            } else if currentStep == 2 {
                                stepTwoInputs // Date, Time, Duration
                            } else {
                                stepThreeInputs // Roster, Cost
                            }
                        }
                        .padding(30)
                    }
                    
                    navigationButtons
                        .padding()
                }
            }
            .padding(30)
            .navigationTitle("Create") // Moved here
            .navigationBarTitleDisplayMode(.inline) // Moved here
            .toolbar { // Moved here
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { router.sheet = nil }
                }
            }
        }
    }
    
    private var stepOneInputs: some View {
        VStack(spacing: 20) {
            PrimaryTextInput(label: "Title",
                             placeholder: "e.g. MNF",
                             text: $viewModel.title,
                             errorMessage: viewModel.validationErrors["title"]
            )
            PrimaryTextInput(label: "Sport",
                             placeholder: "e.g. Soccer",
                             text: $viewModel.sport,
                             errorMessage: viewModel.validationErrors["sport"])
            PrimaryTextInput(label: "Location",
                             placeholder: "Jala",
                             text: $viewModel.location,
                             errorMessage:
                                viewModel.validationErrors["location"])
        }
    }
    
    private var stepTwoInputs: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("DATE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.validationErrors["date_event"] == nil ? Assets.theme.secondaryText : .red)
                
                DatePicker(
                    "Select Date",
                    selection: $viewModel.date_event, 
                    displayedComponents: .date
                )
                .labelsHidden()
                .padding()
                .background(Assets.theme.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.validationErrors["date_event"] == nil ? Color.white.opacity(0.1) : Color.red, lineWidth: 1)
                )
                .accentColor(Assets.theme.primary)
                
                if let errorMessage = viewModel.validationErrors["date_event"] {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("TIME")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.validationErrors["time"] == nil ? Assets.theme.secondaryText : .red)
                
                DatePicker(
                    "Select Time",
                    selection: $viewModel.time,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .padding()
                .background(Assets.theme.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.validationErrors["time"] == nil ? Color.white.opacity(0.1) : Color.red, lineWidth: 1)
                )
                .accentColor(Assets.theme.primary)
                
                if let errorMessage = viewModel.validationErrors["time"] {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            PrimaryTextInput(label: "Duration",
                             placeholder: "e.g. 30",
                             text: $viewModel.duration,
                             errorMessage: viewModel.validationErrors["duration"])
        }
    }
    
    private var stepThreeInputs: some View {
        VStack(spacing: 20) {
            PrimaryTextInput(label: "Roster size",
                             placeholder: "12",
                             text: $viewModel.roster_size,
                             errorMessage: viewModel.validationErrors["roster_size"])
            PrimaryTextInput(label: "Cost",
                             placeholder: "30",
                             text: $viewModel.cost,
                             errorMessage: viewModel.validationErrors["cost"]
            )
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 1 {
                Button("Back") { currentStep -= 1 }
                    .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep < 3 {
                PrimaryButton("Next") {
                    if viewModel.isFormValid(step: currentStep) {
                        currentStep += 1
                    }
                }
            } else {
                PrimaryButton("Finish & Create") {
                    if viewModel.isFormValid(step: currentStep) {
                        viewModel.create()
                    }
                }
                .disabled(viewModel.state.isLoading)
            }
        }
        .padding(.horizontal, 30)
    }
}
