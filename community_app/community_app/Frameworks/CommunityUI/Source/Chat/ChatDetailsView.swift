//
//  ChatDetailsView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/11/09.
//

import Combine
import Foundation
import CommunityCore
import SwiftUI

public struct ChatDetailsView<T: ChatDetailsViewModelProtocol & ObservableObject>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T

    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            switch viewModel.state {
            case .idle:
                Color.clear
                    .onAppear { viewModel.connect() }
            case .loading:
                ProgressView("Connecting to chat...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success:
                chatContent
            case .error(let message):
                VStack(spacing: 12) {
                    Text("Connection Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        viewModel.connect()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Chat Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.connect()
        }
    }
    
    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isFromCurrentUser: true
//                                isFromCurrentUser: message.senderId == viewModel.currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("Type a message...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                            ? Color.gray 
                            : Color.accentColor
                        )
                        .clipShape(Circle())
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

public struct MessageBubbleView: View {
    public let message: ChatMessage
    public let isFromCurrentUser: Bool
    
    public init(message: ChatMessage, isFromCurrentUser: Bool) {
        self.message = message
        self.isFromCurrentUser = isFromCurrentUser
    }
    
    public var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser { Spacer() }
        }
    }
}
