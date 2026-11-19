//
//  ChatFeedView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/11/06.
//

import Foundation
import SwiftUI
import CommunityCore

public struct ChatFeedView<T: DashboardViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    
    public init(viewModel: T) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading chats...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Failed to load chats")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await viewModel.getChats()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success:
                List {
                    if viewModel.dashboardModel.chats.isEmpty {
                        Text("No chats available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(viewModel.dashboardModel.chats, id: \.self) { chat in
                            // Replace with your actual chat cell row view
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.lastContent ?? "")
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                            .onTapGesture {
                                viewModel.chatTapped(roomID: chat.roomId)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
