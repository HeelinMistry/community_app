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
                VStack(spacing: 16) { // Add spacing between feed items
                    // Header or welcome message
                    PrimaryText(label: "Welcome to Your Feed!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)

                    // Placeholder feed items
                    ForEach(0..<10) { index in
                        FeedItemPlaceholder(index: index)
                    }
                }
                .padding() // Padding for the entire scrollable content
            }
            .background(Assets.theme.inputBackground.ignoresSafeArea()) // Using theme color for background
            .navigationTitle("Dashboard") // Set the navigation bar title
            .navigationBarTitleDisplayMode(.large) // Make the title large
            .toolbar { // Add toolbar content
                ToolbarItem(placement: .navigationBarTrailing) { // Place the button on the trailing side
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
        }
    }
}

// A simple placeholder struct to represent a feed item
struct FeedItemPlaceholder: View {
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder for a user's profile picture and name
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Assets.theme.secondaryText) // Using theme color
                VStack(alignment: .leading) {
                    Text("User Name \(index)")
                        .font(.headline)
                        .foregroundColor(Assets.theme.primaryText) // Using theme color
                    Text("Posted 2 hours ago")
                        .font(.subheadline)
                        .foregroundColor(Assets.theme.secondaryText) // Using theme color
                }
            }
            .padding(.bottom, 4)

            // Placeholder for the post content
            Text("This is a placeholder for a feed item's content. It can be a short message, a status update, or a description of an image/video.")
                .font(.body)
                .lineLimit(3) // Limit text to 3 lines
                .foregroundColor(Assets.theme.primaryText) // Using theme color

            // Placeholder for an image or media
            Rectangle()
                .fill(Assets.theme.tertiary.opacity(0.3)) // Using theme color with opacity
                .frame(height: 200)
                .cornerRadius(10)
                .padding(.vertical, 8)

            // Placeholder for actions (e.g., like, comment, share)
            HStack {
                Button {
                    // Action for like
                } label: {
                    Label("Like", systemImage: "hand.thumbsup")
                        .foregroundColor(Assets.theme.primaryText) // Using theme color
                }
                Spacer()
                Button {
                    // Action for comment
                } label: {
                    Label("Comment", systemImage: "text.bubble")
                        .foregroundColor(Assets.theme.primaryText) // Using theme color
                }
                Spacer()
                Button {
                    // Action for share
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .foregroundColor(Assets.theme.primaryText) // Using theme color
                }
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
        .padding()
        .background(Assets.theme.neutral) // Using theme color for the card background
        .cornerRadius(15) // Rounded corners for the card
        .shadow(color: Assets.theme.primaryText.opacity(0.1), radius: 5, x: 0, y: 2) // Using theme color for shadow
    }
}
