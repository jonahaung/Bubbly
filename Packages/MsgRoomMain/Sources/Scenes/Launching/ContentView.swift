// © 2026 Aung Ko Min

import Services
import SwiftUI
import XUI

public struct ContentView: View {
    

    public init() {
        _appLauncher = .init(wrappedValue: .init())
    }
    
    public var body: some View {
        switch appLauncher.route {
        case .loading:
            LaunchScreen(appLauncher: appLauncher)
        case .getStarted:
            AuthFlow(appLauncher: appLauncher)
        case let .main(currentUser):
            ArchitecturalView(
                launcher: appLauncher,
                currentUser: currentUser,
                router: appLauncher.router,
            )
        }
    }
    
    @LazyState private var appLauncher: AppLauncher
}
