//
//  AppLauncher.swift
//  Bubbly
//
//  Created by Aung Ko Min on 18/11/25.
//

import FirebaseAuth
import Foundation
import Observation
import Services
import Database

@MainActor
@Observable
public final class AppLauncher {

	public private(set) var route: Launching.MainRoute = .loading

	public init() {}
}

extension AppLauncher {
	public func startEvaluate() async {
		route = await evaluateRoute()
	}
	@concurrent
	private func evaluateRoute() async -> Launching.MainRoute {
		let hasCompleted = UserDefaults.standard.bool(forKey: Launching.DefaultKeys.getStarted)
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

	public func markGetStartedAsDone(user: CurrentUserModel) {
		let defaults = UserDefaults.standard
		defaults.set(true, forKey: Launching.DefaultKeys.getStarted)
		route = .main(user)
	}
	public func resetGetStarted() async {
		try? Auth.auth().signOut()
		await Store.shared.destory()
		let defaults = UserDefaults.standard
		defaults.set(false, forKey: Launching.DefaultKeys.getStarted)
		await startEvaluate()
	}
}
