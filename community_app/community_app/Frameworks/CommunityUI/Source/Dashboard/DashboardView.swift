//
//  DashboardView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import SwiftUI

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
                    Text("Welcome to Your Feed!")
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
            .navigationTitle("Dashboard") // Set the navigation bar title
            .navigationBarTitleDisplayMode(.large) // Make the title large
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
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    Text("User Name \(index)")
                        .font(.headline)
                    Text("Posted 2 hours ago")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 4)

            // Placeholder for the post content
            Text("This is a placeholder for a feed item's content. It can be a short message, a status update, or a description of an image/video.")
                .font(.body)
                .lineLimit(3) // Limit text to 3 lines

            // Placeholder for an image or media
            Rectangle()
                .fill(Color.secondary.opacity(0.3)) // A light gray rectangle
                .frame(height: 200)
                .cornerRadius(10)
                .padding(.vertical, 8)

            // Placeholder for actions (e.g., like, comment, share)
            HStack {
                Button {
                    // Action for like
                } label: {
                    Label("Like", systemImage: "hand.thumbsup")
                }
                Spacer()
                Button {
                    // Action for comment
                } label: {
                    Label("Comment", systemImage: "text.bubble")
                }
                Spacer()
                Button {
                    // Action for share
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
        .padding()
        .background(Color.white) // Use a white background for the card
        .cornerRadius(15) // Rounded corners for the card
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Subtle shadow
    }
}
