//
//  CreateMatchView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/01.
//

import SwiftUI
import CommunityCore

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
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            PrimaryPicker(
                label: "Sport",
                selection: $viewModel.sport,
                options: Sport.allCases,
                optionLabel: { sport in Text(sport.localizedName) },
                errorMessage: viewModel.validationErrors["sport"]
            )
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
            PrimaryPicker(
                label: "Duration",
                selection: durationBinding,
                options: durationOptions,
                optionLabel: { duration in Text("\(duration) minutes") },
                errorMessage: viewModel.validationErrors["duration"]
            )
        }
    }
    
    private var stepThreeInputs: some View {
        VStack(spacing: 20) {
            PrimaryPicker(
                label: "Roster size",
                selection: rosterSizeBinding,
                options: rosterSizeOptions,
                optionLabel: { size in Text("\(size)") },
                errorMessage: viewModel.validationErrors["roster_size"]
            )
            PrimaryPicker(
                label: "Cost",
                selection: costBinding,
                options: costOptions,
                optionLabel: { cost in Text("\(cost)") },
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

    // Helper properties for the duration picker
    private var durationOptions: [Int] {
        // Generates duration options incrementing by 30 minutes, from 30 up to 300 (5 hours)
        Array(stride(from: 30, through: 300, by: 30))
    }

    private var durationBinding: Binding<Int> {
        Binding<Int>(
            get: {
                // Safely convert viewModel.duration (String) to Int.
                // If conversion fails or if the value is not in `durationOptions`,
                // default to the first option (30 minutes) or a reasonable fallback.
                if let intValue = Int(viewModel.duration), durationOptions.contains(intValue) {
                    return intValue
                }
                return durationOptions.first ?? 30 // Fallback to 30 or the first available option
            },
            set: { newValue in
                viewModel.duration = String(newValue)
            }
        )
    }

    // Helper properties for the roster size picker
    private var rosterSizeOptions: [Int] {
        // Generates roster size options from 1 to 50, incrementing by 1
        Array(1...50)
    }

    private var rosterSizeBinding: Binding<Int> {
        Binding<Int>(
            get: {
                if let intValue = Int(viewModel.roster_size), rosterSizeOptions.contains(intValue) {
                    return intValue
                }
                return rosterSizeOptions.first ?? 1 // Fallback to 1 or the first available option
            },
            set: { newValue in
                viewModel.roster_size = String(newValue)
            }
        )
    }

    // Helper properties for the cost picker
    private var costOptions: [Int] {
        // Generates cost options from 0 to 500, incrementing by 10
        Array(stride(from: 0, through: 500, by: 10))
    }

    private var costBinding: Binding<Int> {
        Binding<Int>(
            get: {
                if let intValue = Int(viewModel.cost), costOptions.contains(intValue) {
                    return intValue
                }
                return costOptions.first ?? 0 // Fallback to 0 or the first available option
            },
            set: { newValue in
                viewModel.cost = String(newValue)
            }
        )
    }
}
