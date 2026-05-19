//  Created by Heelin Mistry on 2026/02/18.
//

import SwiftUI
import CommunityUI

@main
struct CommunitySwiftApp: App {
    @StateObject private var router = NavigationRouter()
    private let container: DependencyContainer
    
    init() {
        Assets.theme = CommunityTheme()
        
        let sharedRouter = NavigationRouter()
        self._router = StateObject(wrappedValue: sharedRouter)
        self.container = DependencyContainer(router: sharedRouter)
    }
    
    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environmentObject(router)
                .environment(\.viewFactory, container)
                .onOpenURL { url in
                    print("onOpenURL triggered with URL: \(url)")
                    // Expected URL format: community-app://com.mistcreation.community-app/match/ID123
                    if url.scheme == "community-app", url.host == "com.mistcreation.community-app" {
                        print("Deep link condition met for scheme: \(url.scheme ?? "nil") and host: \(url.host ?? "nil")") // Added debug print
                        let matchID = url.lastPathComponent
                        print("Extracted matchID from deep link: \(matchID)") // Added debug print
                        router.handleDeepLink(matchID: matchID)
                    } else {
                        print("Deep link condition NOT met. Scheme: \(url.scheme ?? "nil"), Host: \(url.host ?? "nil"). Expected scheme 'community-app' and host 'com.mistcreation.community-app'") // Added debug print for unmet condition
                    }
                }
        }
    }
}

