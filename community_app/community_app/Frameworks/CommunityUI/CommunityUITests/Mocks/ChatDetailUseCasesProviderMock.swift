//
//  ChatDetailUseCasesProviderMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/11/21.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class ChatDetailUseCasesProviderMock: ChatDetailUseCasesProvider {
    let chatsMock = ChatUseCasesMock()
    var chats: any ChatUseCaseProtocol { chatsMock }
}
