// © 2026 Aung Ko Min

import Core
import Database
import FirebaseAuth
import Foundation
import Observation
import XUI

// MARK: - AppLauncher

@MainActor
@Observable
public final class AppLauncher {
    public enum MainRoute: Equatable {
        case loading
        case getStarted
        case main(_ user: CurrentUserModel)
    }

    enum DefaultKeys {
        static let getStarted = "AppLauncher.getStarted"
    }

    public private(set) var route: MainRoute = .loading
    public let router: Router = .shared

    public init() {}
}

public extension AppLauncher {
    func startEvaluate() async {
        let route = evaluateRoute()
        switch route {
        case .getStarted:
            await Store.shared.destory()
            GroupStorage.shared.delete(for: .auth(.currentUserID))
            GroupStorage.shared.delete(for: .auth(.authToken))
        case .loading:
            break
        case let .main(currentUser):
            router.reset()
            if await !Store.shared.hasSetUp(for: currentUser.uid) {
                await Store.shared.start(with: currentUser.uid)
            }
        }
        self.route = route
    }

    private func evaluateRoute() -> MainRoute {
        let hasCompleted = UserDefaults.standard.bool(forKey: DefaultKeys.getStarted)
        if hasCompleted {
            if let user = Auth.auth().currentUser {
                return .main(.init(user))
            }
        }
        return .getStarted
    }

    func markGetStartedAsDone(user: CurrentUserModel) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: DefaultKeys.getStarted)
        route = .main(user)
    }

    func resetGetStarted() async {
        try? Auth.auth().signOut()
        await Store.shared.destory()
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: DefaultKeys.getStarted)
        await startEvaluate()
    }
}
