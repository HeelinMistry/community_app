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
        VStack(alignment: .leading, spacing: 8) {
            // Match Title
            Text(match.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.primaryText)
                .padding(.bottom, 4)
            
            // Date and Time
            HStack {
                Image(systemName: "calendar")
                Text(formatDate(match.start_datetime))
                    .foregroundStyle(Assets.theme.primaryText)
            }
            .font(.subheadline)
            .foregroundColor(Assets.theme.secondaryText)
            
            // Location
            HStack {
                Image(systemName: "location.fill")
                Text(match.location)
                    .foregroundStyle(Assets.theme.primaryText)
            }
            .font(.subheadline)
            .foregroundColor(Assets.theme.secondaryText)
            
            // Cost and Roster Size
            HStack {
                Image(systemName: "tag.fill")
                Text("Cost: \(match.cost)")
                    .foregroundStyle(Assets.theme.primaryText)
                Spacer()
                Image(systemName: "person.3.fill")
                Text("Players: \(match.joined)/\(match.roster_size)")
                    .foregroundStyle(Assets.theme.primaryText)
            }
            .font(.subheadline)
            .foregroundColor(Assets.theme.secondaryText)
            .padding(.vertical, 4)
            
            // Host and Cancelled Status
            HStack {
                if match.is_host {
                    Label("You are Host", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(Assets.theme.primaryAccent)
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
                Button {
                    // Action for joining/leaving
                } label: {
                    Label(match.is_joined ? "Leave" : "Join", systemImage: match.is_joined ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
                        .foregroundColor(Assets.theme.primaryText)
                }
                Spacer()
                Button {
                    // Action for sharing
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .foregroundColor(Assets.theme.primaryText)
                }
            }
            .font(.subheadline)
            .padding(.horizontal)
        }
        .padding()
        .background(Assets.theme.neutral)
        .cornerRadius(15)
        .shadow(color: Assets.theme.primaryText.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ isoString: String) -> String {
        if let date = Self.isoDateFormatter.date(from: isoString) {
            return Self.dateFormatter.string(from: date)
        }
        return "Unknown Date"
    }
}
