//
//  EventFeedView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/17.
//

import Foundation
import SwiftUI

public struct EventFeedView<T: DashboardViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @Binding var selectedTab: MatchTab
    
    public var body: some View {
        Picker("Match Type", selection: $selectedTab) {
            ForEach(MatchTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        ScrollView {
            VStack(spacing: 16) {
                let matchesToShow = selectedTab == .upcoming ? viewModel.dashboardModel.upcomingMatches : viewModel.dashboardModel.historyMatches
                
                if matchesToShow.isEmpty {
                    Text(selectedTab == .upcoming ?
                         "No upcoming matches found. Create one to get started!" :
                            "No past matches found.")
                    .font(.headline)
                    .foregroundColor(Assets.theme.secondaryText)
                    .padding()
                } else {
                    ForEach(matchesToShow, id: \.match_id) { match in
                        MatchFeedItemView(match: match)
                    }
                    Spacer()
                }
            }
        }
    }
}
