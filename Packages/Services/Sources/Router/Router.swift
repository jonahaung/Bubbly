//
//  Router.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 23/10/24.
//

import Combine
import Core
import Database
import SwiftUI
import XUI

@MainActor
@Observable
public class Router {

	public static let shared = Router()

	public var tab: TabPath = .inbox
	public var fullScreen: NavPath?
	public var sheet: NavPath?

	public var navRouters = TabPath.allCases.map { NavRouter($0) }

	public var currentNavRouter: NavRouter {
		navRouters.first(where: { $0.id == tab })!
	}

	public var currentNavPath: NavPath? {
		currentNavRouter.navPath.last
	}

	public func navRouter(for tab: TabPath) -> NavRouter {
		navRouters.first(where: { $0.id == tab })!
	}

	private init() {
		trackItemsChanges()
	}
	func trackItemsChanges() {
		withObservationTracking {
			_ = currentNavRouter.navPath
		} onChange: { [weak self] in
			guard let self else {
				return
			}
			Task { @MainActor in
				if currentNavRouter.navPath.isEmpty && tabBarVisibility == .hidden {
					tabBarVisibility = .visible
				}
				trackItemsChanges()
			}
		}
	}
	public func push(_ path: NavPath) {
		if case .conversation = path {
			tabBarVisibility = .hidden
			DispatchQueue.delay {
				self.currentNavRouter.push(path)
			}
		} else {
			currentNavRouter.push(path)
		}
	}

	public func presentFullScreen(_ path: NavPath?) {
		fullScreen = path
	}

	public func dismissFullScreen() {
		fullScreen = nil
	}

	public func presentSheet(_ path: NavPath?) {
		sheet = path
	}

	public func dismissSheet() {
		sheet = nil
	}

	public var tabBarVisibility: Visibility = .automatic
}
