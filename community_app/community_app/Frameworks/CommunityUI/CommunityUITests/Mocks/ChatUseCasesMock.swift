//
//  ChatUseCasesMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/30.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class ChatUseCasesMock: ChatUseCaseProtocol, @unchecked Sendable {

    var chatResult: Result<Chats, Error>?
    func userRelatedChats() async throws -> Chats {
        if let result = chatResult {
            switch result {
            case .success(let response): return response
            case .failure(let error): throw error
            }
        }
        fatalError("Result not set in ChatUseCaseProtocol")
    }
    
}
