// © 2026 Aung Ko Min

import Services
import SwiftUI

public struct ContentView: View {

    let appLauncher: AppLauncher
    let router: Router
    
    public init(appLauncher: AppLauncher, router: Router) {
        self.appLauncher = appLauncher
        self.router = router
    }
    
    public var body: some View {
        switch appLauncher.route {
        case .loading:
            LaunchScreen(appLauncher: appLauncher)
        case .getStarted:
            AuthFlow(appLauncher: appLauncher)
        case .main(let currentUser):
            let currentUserRepository = CurrentUserRepository(currentUser)
            let container = AppDependencyContainer(
                currentUserRepository: currentUserRepository
            )
            RootTabView(coordinator: .init(appLauncher: appLauncher, container: container, router: router))
        }
    }

}
