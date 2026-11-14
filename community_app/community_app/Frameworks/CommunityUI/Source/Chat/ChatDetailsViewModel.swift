//
//  MatchDetailsViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/14.
//
import Combine
import Foundation
import CommunityCore
import SwiftUI

@MainActor
public protocol ChatDetailsViewModelProtocol: StateDrivenViewModel where DataType == Chats {
    var messages: [ChatMessage] { get }
    var inputText: String { get set }
    
    func connect()
    func sendMessage()
}

@MainActor
public final class ChatDetailsViewModel: ChatDetailsViewModelProtocol {
    
    @Published public private(set) var state: ViewState<Chats> = .idle
    @Published public private(set) var messages: [ChatMessage] = []
    @Published public var inputText: String = ""
 
    private let room_id: String
    private let router: NavigationRouter
    private let useCases: any ChatDetailUseCasesProvider
    private var fetchTask: Task<Void, Never>?
    private var webSocketTask: URLSessionWebSocketTask?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        useCases: any ChatDetailUseCasesProvider,
        router: NavigationRouter,
        room_id: String
    ) {
        self.useCases = useCases
        self.router = router
        self.room_id = room_id
    }
    
    public func connect() {
        if state == .loading { return }
        
        fetchTask?.cancel()
        state = .loading
        
        fetchTask = Task {
            do {
                // 1. Establish connection via repository/use cases
                try await useCases.chats.connect(request: .init(room_id))
                
                if !Task.isCancelled {
                    self.state = .success(Chats())
                    // Start listening to incoming WebSocket messages or polling history
//                    listenForMessages()
                }
            } catch {
                if !Task.isCancelled {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    public func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let contentToSend = trimmed
        inputText = ""
        
        Task {
            do {
                try await useCases.chats.send(content: contentToSend)
                
                // Note: If your backend broadcasts back to the sender, the message will 
                // arrive via listenForMessages(). Otherwise, append optimistically here.
            } catch {
                print("Failed to send message: \(error)")
            }
        }
    }
    
    static var isoDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }
}
