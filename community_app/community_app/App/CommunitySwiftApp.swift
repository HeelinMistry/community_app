//  Created by Heelin Mistry on 2026/02/18.
//

import SwiftUI
import CommunityUI

@main
struct CommunitySwiftApp: App {
    let container = DependencyContainer()
    
    init() {
        Assets.theme = CommunityTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView(viewModel: container.makeLoginViewModel())
        }
    }
}
