//
//  MatchDetailsView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/13.
//

import SwiftUI
import Foundation
import CommunityCore
import MapKit
import CoreLocation

// MARK: - File-level Helper Functions and Formatters

private let fileDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short
    return formatter
}()

private let fileISO8601DateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
    return formatter
}()

private func fileFormatDate(_ isoString: String) -> String {
    if let date = fileISO8601DateFormatter.date(from: isoString) {
        return fileDateFormatter.string(from: date)
    }
    return "Unknown Date"
}

private func fileFormattedDistance(from userLocation: CLLocation, to matchLocation: CLLocation) -> String {
    let distanceInMeters = userLocation.distance(from: matchLocation)
    let distanceMeasurement = Measurement(value: distanceInMeters, unit: UnitLength.kilometers)
    
    let formatter = MeasurementFormatter()
    formatter.unitStyle = .long
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 1
    
    return formatter.string(from: distanceMeasurement)
}

// MARK: - File-level Helper Views

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

private struct NotificationButtonView<T: MatchDetailsViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    
    var body: some View {
        Button {
            Task {
                if viewModel.notificationState == .reminderSet {
                    await viewModel.cancelMatchNotification()
                } else {
                    await viewModel.scheduleMatchNotification()
                }
            }
        } label: {
            if viewModel.notificationState == .updating {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Assets.theme.primaryAccent)
            } else {
                Label(viewModel.notificationState == .reminderSet ? "Cancel Reminder" : "Set Reminder",
                      systemImage: viewModel.notificationState == .reminderSet ? "bell.slash.fill" : "bell.badge")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(viewModel.notificationState == .reminderSet ? .orange : Assets.theme.primaryAccent)
        .disabled(viewModel.notificationState == .updating)
        .padding(.top, 8)
    }
}

private struct UpcomingMatchActionsView<T: MatchDetailsViewModelProtocol>: View {
    let match: MatchDetailResponse
    @ObservedObject var viewModel: T
    
    var body: some View {
        VStack(spacing: 16) {
            // 1. Join/Leave Button
            Button(
                action: { viewModel.toggleMatchParticipation()},
                label: {
                    if viewModel.isTogglingParticipation {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(match.is_joined ? .red : Assets.theme.primaryAccent)
                    } else {
                        Label(match.is_joined ? "Leave Match" : "Join Match", systemImage: match.is_joined ? "person.crop.circle.badge.minus" : "person.crop.circle.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                })
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(match.is_joined ? .red : Assets.theme.primaryAccent)
            .disabled(viewModel.isTogglingParticipation)
            
            if match.is_host {
                Button {
                    viewModel.toggleMatchCancellation()
                } label: {
                    if viewModel.isTogglingCancellation {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(match.is_cancelled ? Assets.theme.primaryAccent : .red)
                    } else {
                        Label(match.is_cancelled ? "Uncancel" : "Cancel", systemImage: match.is_cancelled ? "arrow.uturn.backward.circle.fill" : "xmark.octagon.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(match.is_cancelled ? Assets.theme.primaryAccent : .red)
                .disabled(viewModel.isTogglingCancellation)
            }
            
            // 2. Notification Button
            if match.is_joined && !match.is_cancelled {
                NotificationButtonView(viewModel: viewModel)
            }
        }
    }
}

private struct PastMatchActionsView: View {
    var body: some View {
        Text("Match has concluded")
            .font(.caption)
            .foregroundColor(Assets.theme.secondaryText)
        
        Button(action: { /* Navigate to Rate Match View */ }, label: {
            Label("Rate Match", systemImage: "star.fill")
                .frame(maxWidth: .infinity)
        }).buttonStyle(.bordered)
        .controlSize(.large)
        .tint(Assets.theme.primaryAccent)
        .padding(.top, 8)
        
    }
}

private struct MatchDetailsActionButtons<T: MatchDetailsViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isUpcoming, let match = viewModel.matchDetailResponse {
                UpcomingMatchActionsView(match: match, viewModel: viewModel)
            } else {
                PastMatchActionsView()
            }
        }
    }
}

private struct MatchDetailsSuccessContentView<T: MatchDetailsViewModelProtocol>: View {
    let match: MatchDetailResponse
    @ObservedObject var viewModel: T
    @Binding var mapCameraPosition: MapCameraPosition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Match Overview
            Text(match.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.primaryAccent)
                .padding(.bottom, 8)

            MatchDetailRow(label: "Date & Time", value: fileFormatDate(match.start_datetime), systemImage: "calendar")
            MatchDetailRow(label: "Location", value: match.location, systemImage: "location.fill")
            
            // MARK: - Distance from User
            if let userLocation = viewModel.lastKnownLocation,
               match.latitude != 0.0 || match.longitude != 0.0 {
                let matchCLLocation = CLLocation(latitude: match.latitude, longitude: match.longitude)
                MatchDetailRow(label: "Distance from you", value: fileFormattedDistance(from: userLocation, to: matchCLLocation), systemImage: "figure.walk.circle.fill")
            } else {
                if !viewModel.isAuthorized {
                    Text("Location access denied. Please enable in Settings to see distance.")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.leading)
                } else if viewModel.lastKnownLocation == nil {
                    Text("Getting your location...")
                        .font(.subheadline)
                        .foregroundColor(Assets.theme.secondaryText.opacity(0.7))
                        .padding(.leading)
                }
            }
            
            MatchDetailRow(label: "Cost", value: match.cost, systemImage: "tag.fill")
            MatchDetailRow(label: "Players", value: "\(match.current_roster) / \(match.roster_size) players joined", systemImage: "person.3.fill")

            Divider()
            
            // MARK: - Map View for Location
            VStack(alignment: .leading, spacing: 10) {
                Text("Match Location")
                    .font(.headline)
                    .foregroundColor(Assets.theme.secondaryText)
                
                if match.latitude != 0.0 || match.longitude != 0.0 {
                    Map(position: $mapCameraPosition) {
                        Marker(match.location, coordinate: CLLocationCoordinate2D(latitude: match.latitude, longitude: match.longitude))
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onAppear {
                        mapCameraPosition = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: match.latitude, longitude: match.longitude),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }

                    Button {
                        viewModel.showDirectionsOnMap()
                    } label: {
                        Label("Get Directions", systemImage: "car.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Assets.theme.primaryAccent) 
                    .disabled(viewModel.lastKnownLocation == nil || match.latitude == 0.0 || match.longitude == 0.0 || !viewModel.isAuthorized)
                    .padding(.top, 8)

                } else {
                    Text("Location coordinates not available.")
                        .font(.subheadline)
                        .foregroundColor(Assets.theme.secondaryText.opacity(0.7))
                        .padding(.top, 4)
                }
            }
            
            Divider()
                .foregroundStyle(Assets.theme.primary.opacity(0.3))

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
                .foregroundStyle(Assets.theme.primary.opacity(0.3))

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
                .foregroundStyle(Assets.theme.primary.opacity(0.3))

            // MARK: - Action Buttons
            MatchDetailsActionButtons(viewModel: viewModel)

            ShareLink(item: viewModel.matchURL, subject: Text("Match Invitation")) {
                Label("Share Match", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(Assets.theme.secondaryText)
            .padding(.top, 8)
        }
    }
}

// MARK: - Main MatchDetailsView

public struct MatchDetailsView<T: MatchDetailsViewModelProtocol>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T
    
    // State to control the map's camera position
    @State private var mapCameraPosition: MapCameraPosition = .automatic

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
                    MatchDetailsSuccessContentView(match: match, viewModel: viewModel, mapCameraPosition: $mapCameraPosition)
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
            viewModel.matchDetail()
            Task {
                await viewModel.requestLocationAuthorization()
            }
        }
    }
}
