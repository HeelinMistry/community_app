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
                    VStack(alignment: .leading, spacing: 16) {
                        // MARK: - Match Overview
                        Text(match.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Assets.theme.primaryAccent)
                            .padding(.bottom, 8)

                        MatchDetailRow(label: "Date & Time", value: formatDate(match.start_datetime), systemImage: "calendar")
                        MatchDetailRow(label: "Location", value: match.location, systemImage: "location.fill")
                        MatchDetailRow(label: "Cost", value: match.cost, systemImage: "tag.fill")
                        MatchDetailRow(label: "Players", value: "\(match.current_roster) / \(match.roster_size) players joined", systemImage: "person.3.fill")

                        Divider()

                        // MARK: - Status Indicators
                        VStack(alignment: .leading, spacing: 8) {
                            if match.is_host {
                                Label("You are the Host", systemImage: "star.fill")
                                    .font(.body)
                                    .foregroundColor(Assets.theme.primaryAccent)
                            }
                            if match.is_joined {
                                Label("You have joined this match", systemImage: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.green)
                            } else {
                                Label("You have not joined this match", systemImage: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(Assets.theme.secondaryText)
                            }
                            if match.is_cancelled {
                                Label("This match has been Cancelled", systemImage: "xmark.octagon.fill")
                                    .font(.body)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)

                        Divider()

                        // MARK: - Player List
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Participants")
                                .font(.headline)
                                .foregroundColor(Assets.theme.secondaryText)

                            if match.player_list.isEmpty {
                                Text("No players have joined yet.")
                                    .font(.subheadline)
                                    .foregroundColor(Assets.theme.secondaryText.opacity(0.7))
                                    .padding(.top, 4)
                            } else {
                                ForEach(match.player_list, id: \.self) { player in
                                    HStack {
                                        Image(systemName: "person.crop.circle")
                                            .foregroundColor(Assets.theme.primaryAccent)
                                        Text(player)
                                            .font(.body)
                                            .foregroundColor(Assets.theme.primaryAccent)
                                    }
                                }
                            }
                        }

                        Divider()

                        // MARK: - Action Buttons
                        HStack {
                            Button {
                                viewModel.toggle_match_participation()
                            } label: {
                                if viewModel.isTogglingParticipation {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(match.is_joined ? .red : Assets.theme.primaryAccent)
                                } else {
                                    Label(match.is_joined ? "Leave Match" : "Join Match", systemImage: match.is_joined ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(match.is_joined ? .red : Assets.theme.primaryAccent)
                            .disabled(viewModel.isTogglingParticipation)

                            // Host-specific button for cancelling/uncancelling
                            if match.is_host {
                                Button {
                                    viewModel.toggle_match_cancellation()
                                } label: {
                                    if viewModel.isTogglingCancellation {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(match.is_cancelled ? Assets.theme.primaryAccent : .red)
                                    } else {
                                        Label(match.is_cancelled ? "Uncancel" : "Cancel", systemImage: match.is_cancelled ? "checkmark.octagon.fill" : "xmark.octagon.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .tint(match.is_cancelled ? Assets.theme.primaryAccent : .red)
                                .disabled(viewModel.isTogglingCancellation)
                            }
                        }
                        .padding(.top, 16)
                        
                        // Share button - using ShareLink for iOS 16+ for a standard approach
                        if #available(iOS 16.0, *) {
                            ShareLink(item: "Check out this match: \(match.title) at \(match.location) on \(formatDate(match.start_datetime))!", subject: Text("Match Invitation"), message: Text("Join me for \(match.sport) at \(match.location)!")) {
                                Label("Share Match", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .tint(Assets.theme.secondaryText)
                            .padding(.top, 8)
                        } else {
                            // Fallback for older iOS versions
                            Button {
                                // Action for sharing (e.g., UIActivityViewController)
                            } label: {
                                Label("Share Match", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .tint(Assets.theme.secondaryText)
                            .padding(.top, 8)
                        }

                    } // End of main content stack
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

    // Helper view for consistent detail rows
    private struct MatchDetailRow: View {
        let label: String
        let value: String
        let systemImage: String

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Label(label, systemImage: systemImage)
                    .font(.headline)
                    .foregroundColor(Assets.theme.secondaryText)
                Text(value)
                    .font(.title3)
                    .foregroundColor(Assets.theme.primaryAccent)
            }
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
