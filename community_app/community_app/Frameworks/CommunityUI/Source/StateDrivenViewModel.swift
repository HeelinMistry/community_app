//
//  StateDrivenViewModel.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/04/29.
//

import Foundation
import Combine

@MainActor
public protocol StateDrivenViewModel: ObservableObject {
    associatedtype DataType: Equatable & Sendable
    var state: ViewState<DataType> { get }
}
