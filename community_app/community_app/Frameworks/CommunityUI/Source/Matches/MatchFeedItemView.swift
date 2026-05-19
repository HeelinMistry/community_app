//
//  MatchFeedItemView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/08.
//

import SwiftUI
import CommunityCore

// A new struct to display a single match, replacing FeedItemPlaceholder
struct MatchFeedItemView: View {
    @EnvironmentObject private var router: NavigationRouter
    let match: MatchResponse
    
    // Date formatter for start_datetime
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // ISO8601DateFormatter for parsing the input string
    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()
    
    var body: some View {
        // Wrap the entire content of the match item in a NavigationLink
        // The destination is the new MatchDetailsView, passing the current match
        // Use the 'value' initializer for NavigationLink to leverage NavigationStack's navigationDestination
        NavigationLink(value: Destination.detail(match_id: match.match_id)) {
            VStack(alignment: .leading, spacing: 8) {
                // Match Title
                PrimaryText(label: match.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                // Date and Time
                HStack {
                    Image(systemName: "calendar")
                    PrimaryText(label: formatDate(match.start_datetime))
                }
                .font(.subheadline)
                
                // Location
                HStack {
                    Image(systemName: "location.fill")
                    PrimaryText(label: match.location)
                }
                .font(.subheadline)
                .foregroundColor(Assets.theme.secondaryText)
                
                // Cost and Roster Size
                HStack {
                    Image(systemName: "tag.fill")
                    PrimaryText(label: "Cost: \(match.cost)")
                    Spacer()
                    Image(systemName: "person.3.fill")
                    PrimaryText(label: "Players: \(match.joined)/\(match.roster_size)")
                }
                .font(.subheadline)
                .foregroundColor(Assets.theme.secondaryText)
                .padding(.vertical, 4)
                
                // Host, Joined, and Cancelled Status Indicators
                HStack {
                    if match.is_host {
                        Label("You are Host", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(Assets.theme.primaryAccent)
                    }
                    if match.is_joined {
                        Label("Joined", systemImage: "person.badge.checkmark.fill") // A clear icon for joined status
                            .font(.caption)
                            .foregroundColor(Assets.theme.primaryAccent) // Use accent color for positive status
                    }
                    Spacer()
                    if match.is_cancelled {
                        Label("Cancelled", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red) // Standard red for cancelled
                    }
                }
                .padding(.top, 4)
                
                HStack {
                    ShareLink(
                        item: URL(string: "community-app://com.mistcreation.community-app/match/\(match.match_id)")!,
                        subject: Text("Match Invitation")
                    ) {
                        Label("Share Match", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(Assets.theme.secondaryText)
                    .padding(.top, 8)
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
            .padding()
            .background(Assets.theme.inputBackground)
            .cornerRadius(15)
            .shadow(color: Assets.theme.primaryText.opacity(0.1), radius: 5, x: 0, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ isoString: String) -> String {
        if let date = Self.isoDateFormatter.date(from: isoString) {
            return Self.dateFormatter.string(from: date)
        }
        return "Unknown Date"
    }
}
