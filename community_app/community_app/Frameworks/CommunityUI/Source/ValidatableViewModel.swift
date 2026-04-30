//
//  ValidatableViewModel.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/30.
//

@MainActor
public protocol ValidatableViewModel: StateDrivenViewModel {
    var validationErrors: [String: String] { get set }
    var isFormValid: Bool { get }
}
