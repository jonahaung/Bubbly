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

    public init() {}
}

public extension AppLauncher {
    func startEvaluate(router: Router) async {
        let route = evaluateRoute()
        switch route {
        case .getStarted:
            router.reset()
            await Store.shared.destory()
            GroupStorage.shared.delete(for: .auth(.currentUserID))
            await PendingDeeplinkStore.shared.setMainRouteReady(false)
        case .loading:
            break
        case let .main(currentUser):
            GroupStorage.shared.save(currentUser.uid, for: .auth(.currentUserID))
            await Store.shared.start(with: currentUser.uid)
            await PendingDeeplinkStore.shared.setMainRouteReady(true)
            await PendingDeeplinkStore.shared.drainIfReady()
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

    func markGetStartedAsDone(user: CurrentUserModel, router: Router) async {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: DefaultKeys.getStarted)
        router.reset()
        GroupStorage.shared.save(user.uid, for: .auth(.currentUserID))
        await Store.shared.start(with: user.uid)
        await PendingDeeplinkStore.shared.setMainRouteReady(true)
        await PendingDeeplinkStore.shared.drainIfReady()
        route = .main(user)
    }

    func resetGetStarted(router: Router) async throws {
        try Auth.auth().signOut()
        router.reset()
        await Store.shared.destory()
        await PendingDeeplinkStore.shared.setMainRouteReady(false)
        GroupStorage.shared.delete(for: .auth(.currentUserID))
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: DefaultKeys.getStarted)
        await startEvaluate(router: router)
    }
}
