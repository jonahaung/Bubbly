//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import FirebaseAuth
import Foundation
import Observation

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
    func startEvaluate() async {
        route = await evaluateRoute()
    }
    private func evaluateRoute() async -> MainRoute {
        let hasCompleted = UserDefaults.standard.bool(forKey: DefaultKeys.getStarted)
        if hasCompleted {
            if let user = Auth.auth().currentUser {
                if await !Store.shared.hasSetUp(for: user.uid) {
                    await Store.shared.start(with: user.uid)
                }
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
