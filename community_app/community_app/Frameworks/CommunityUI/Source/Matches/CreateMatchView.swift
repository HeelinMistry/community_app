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
    
    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Assets.theme.inputBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        PrimaryTextInput(
                            label: "Title",
                            placeholder: "e.g. MNF",
                            text: $viewModel.title,
                            errorMessage: viewModel.validationErrors["title"]
                        )
                        PrimaryTextInput(
                            label: "Sport",
                            placeholder: "e.g. Soccer",
                            text: $viewModel.sport,
                            errorMessage: viewModel.validationErrors["sport"]
                        )
                        PrimaryTextInput(
                            label: "Duration",
                            placeholder: "e.g. 30",
                            text: $viewModel.duration,
                            errorMessage: viewModel.validationErrors["duration"]
                        )
                        PrimaryTextInput(
                            label: "Date",
                            placeholder: "e.g. 03/04/2026",
                            text: $viewModel.date_event,
                            errorMessage: viewModel.validationErrors["date_event"]
                        )
                        PrimaryTextInput(
                            label: "Time",
                            placeholder: "e.g. 17:00",
                            text: $viewModel.time,
                            errorMessage: viewModel.validationErrors["time"]
                        )
                        PrimaryTextInput(
                            label: "Roster size",
                            placeholder: "12",
                            text: $viewModel.roster_size,
                            errorMessage: viewModel.validationErrors["roster_size"]
                        )
                        PrimaryTextInput(
                            label: "Cost",
                            placeholder: "30",
                            text: $viewModel.cost,
                            errorMessage: viewModel.validationErrors["cost"]
                        )
                        PrimaryTextInput(
                            label: "Location",
                            placeholder: "Jala",
                            text: $viewModel.location,
                            errorMessage: viewModel.validationErrors["location"]
                        )
                        
                        PrimaryButton("Create Account") {
                            if viewModel.isFormValid {
                                viewModel.create()
                            }
                        }
                        .disabled(viewModel.state.isLoading)
                    }
                }
                .padding(30)
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { router.sheet = nil }
                }
            }
        }
    }
}
