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
                    // Expected formats: 
                    // community-app://com.mistcreation.community-app/match/m_c96a2735
                    // community-app://com.mistcreation.community-app/product/p_689d3aab
                    if url.scheme == "community-app", url.host == "com.mistcreation.community-app" {
                        print("Deep link condition met for scheme and host.")
                        
                        let pathComponents = url.pathComponents
                        // pathComponents typically contains ["/", type, id]
                        guard pathComponents.count >= 3 else {
                            print("Invalid deep link path structure: \(url.path)")
                            return
                        }
                        
                        let type = pathComponents[1] // "match" or "product"
                        let id = pathComponents[2]   // The unique identifier
                        
                        print("Extracted deep link type: \(type), ID: \(id)")
                        router.handleDeepLink(type: type, id: id)
                    } else {
                        print("Deep link condition NOT met. Scheme: \(url.scheme ?? "nil"), Host: \(url.host ?? "nil")")
                    }
                }
        }
    }
}
