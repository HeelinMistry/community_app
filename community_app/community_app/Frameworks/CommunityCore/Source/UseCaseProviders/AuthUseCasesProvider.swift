//
//  AuthUseCasesProvider.swift
//  CommunityCore
//
//  Created by Heelin Mistry on 2026/04/27.
//

/// A provider protocol for various authentication-related use cases.
@MainActor
public protocol AuthUseCasesProvider {
    
    /// The use case for verifying a user's login credentials.
    var verifyLogin: VerifyUserLoginUseCaseProtocol { get }
//    var register: RegisterUseCaseProtocol { get }
    // Add future auth-related use cases here
}
