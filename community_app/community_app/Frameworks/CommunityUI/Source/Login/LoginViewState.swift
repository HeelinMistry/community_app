//
//  LoginViewState.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/27.
//

import CommunityCore

/// Represents the various states of the login process in the user interface.
public enum LoginViewState: Equatable {
    /// The initial or reset state, where no login operation is active.
    case idle
    /// The state indicating that a login operation is currently in progress.
    case loading
    /// The state indicating that the login operation was successful, providing the `LoginResponse`.
    case success(LoginResponse)
    /// The state indicating that the login operation failed, providing an error message.
    case error(String)
}
