//
//  MatchDetailsView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/13.
//

import SwiftUI
import Foundation
import CommunityCore

public struct MatchDetailsView<T: MatchDetailsViewModelProtocol>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T

    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch viewModel.state {
                case .idle:
                    Text("Loading match details...")
                        .foregroundColor(Assets.theme.secondaryText)
                case .loading:
                    ProgressView("Loading Match Details...")
                        .controlSize(.large)
                case .success(let match):
                    // Match Title
                    Text(match.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Assets.theme.primaryAccent)
                        .padding(.bottom, 8)

                    // Date and Time
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Date & Time", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(Assets.theme.secondaryText)
                        Text(formatDate(match.start_datetime))
                            .font(.title3)
                            .foregroundColor(Assets.theme.primaryAccent)
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Location", systemImage: "location.fill")
                            .font(.headline)
                            .foregroundColor(Assets.theme.secondaryText)
                        Text(match.location)
                            .font(.title3)
                            .foregroundColor(Assets.theme.primaryAccent)
                    }

                    // Cost
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Cost", systemImage: "tag.fill")
                            .font(.headline)
                            .foregroundColor(Assets.theme.secondaryText)
                        Text(match.cost)
                            .font(.title3)
                            .foregroundColor(Assets.theme.primaryAccent)
                    }

                    // Roster Size
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Players", systemImage: "person.3.fill")
                            .font(.headline)
                            .foregroundColor(Assets.theme.secondaryText)
                        Text("\(match.current_roster) / \(match.roster_size) players joined")
                            .font(.title3)
                            .foregroundColor(Assets.theme.primaryAccent)
                    }

                    // Host Status
                    if match.is_host {
                        Label("You are the Host", systemImage: "star.fill")
                            .font(.body)
                            .foregroundColor(Assets.theme.primaryAccent)
                            .padding(.vertical, 4)
                    }

                    // Joined Status
                    if match.is_joined {
                        Label("You have joined this match", systemImage: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.green)
                            .padding(.vertical, 4)
                    } else {
                        Label("You have not joined this match", systemImage: "xmark.circle.fill")
                            .font(.body)
                            .foregroundColor(Assets.theme.secondaryText)
                            .padding(.vertical, 4)
                    }

                    // Cancelled Status
                    if match.is_cancelled {
                        Label("This match has been Cancelled", systemImage: "xmark.octagon.fill")
                            .font(.body)
                            .foregroundColor(.red)
                            .padding(.vertical, 4)
                    }

                    // Action Buttons
                    HStack {
                        Button {
                            // Action for joining/leaving
                            viewModel.toggle_match_participation()
                        } label: {
                            Label(match.is_joined ? "Leave Match" : "Join Match", systemImage: match.is_joined ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(match.is_joined ? .red : Assets.theme.primaryAccent)

                        Spacer()

                        Button {
                            // Action for sharing
                        } label: {
                            Label("Share Match", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(Assets.theme.secondaryText)
                    }
                    .padding(.top, 16)
                case .error(let message):
                    Text("Error: \(message)")
                        .foregroundColor(.red)
                        .font(.headline)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.matchDetail() // Trigger data fetch when view appears
        }
    }

    private func formatDate(_ isoString: String) -> String {
        if let date = Self.isoDateFormatter.date(from: isoString) {
            return Self.dateFormatter.string(from: date)
        }
        return "Unknown Date"
    }
}

private extension MatchDetailsView {
    // Date formatter for start_datetime, similar to MatchFeedItemView but with full date style
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }

    // ISO8601DateFormatter for parsing the input string
    static var isoDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }
}
