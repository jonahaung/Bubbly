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

	private let defaults = UserDefaults.standard

	public init() {}
}

extension AppLauncher {
	public func startEvaluate() {
		route = evaluateRoute()
	}
	private func evaluateRoute() -> Launching.MainRoute {
		let hasCompleted = defaults.bool(forKey: Launching.DefaultKeys.getStarted)
		if hasCompleted {
			if let user = Auth.auth().currentUser {
				return .main(.init(user))
			}
		}
		return .getStarted
	}

	public func markGetStartedAsDone(user: CurrentUserModel) {
		defaults.set(true, forKey: Launching.DefaultKeys.getStarted)
		route = .main(user)
	}
	public func resetGetStarted() {
		try? Auth.auth().signOut()
		defaults.set(false, forKey: Launching.DefaultKeys.getStarted)
		startEvaluate()
	}
}
