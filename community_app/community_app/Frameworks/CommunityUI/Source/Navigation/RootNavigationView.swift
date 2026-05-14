//
//  RootNavigationView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/04/29.
//

import SwiftUI

struct RootNavigationView: View {
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.viewFactory) var factory
    
    var body: some View {
        if router.isAuthenticated {
            NavigationStack(path: $router.path) {
                factory.makeDashboardView()
                    .navigationDestination(for: Destination.self) { destination in
                        buildDestination(destination)
                    }
                    .sheet(item: $router.sheet) { sheet in
                        buildSheet(sheet)
                    }
                    .alert(item: $router.alertItem) { alert in
                        Alert(
                            title: Text(alert.title),
                            message: Text(alert.message),
                            dismissButton: alert.dismissButton
                        )
                    }
            }
        } else {
            NavigationStack(path: $router.path) {
                factory.makeLoginView()
                    .navigationDestination(for: Destination.self) { destination in
                        buildDestination(destination)
                    }
                    .sheet(item: $router.sheet) { sheet in
                        buildSheet(sheet)
                    }
                    .alert(item: $router.alertItem) { alert in
                        Alert(
                            title: Text(alert.title),
                            message: Text(alert.message),
                            dismissButton: alert.dismissButton
                        )
                    }
            }
        }
    }
    
    @ViewBuilder
    private func buildDestination(_ destination: Destination) -> some View {
        switch destination {
        case .login: factory.makeLoginView()
        case .dashboard: factory.makeDashboardView()
        case .detail(let match_id): factory.makeDetailMatchView(match_id)
        }
    }
    
    @ViewBuilder
    private func buildSheet(_ sheet: SheetDestination) -> some View {
        switch sheet {
        case .registration:
            factory.makeRegistrationView()
        case .createMatch:
            factory.makeCreateMatchView()
        }
    }
}
