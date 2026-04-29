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
        }
    }
}
