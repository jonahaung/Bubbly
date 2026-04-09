//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import SwiftUI
import XUI

public struct Route: Sendable, Hashable, Identifiable {
	public var tabPath: TabPath
	public var navPaths: [NavPath]
	public var id: TabPath { tabPath }
}
@MainActor
@Observable
public final class Router {

	public var routes = [TabPath: [NavPath]]()
	@ObservationIgnored
	public var selectedTab: TabPath
	public var sheet: NavPath?

	public init(_ selected: TabPath) {
		selectedTab = selected
		TabPath.allCases.forEach { each in
			routes[each] = []
		}
	}

	public func navPaths(for tab: TabPath) -> [NavPath] {
		routes[tab] ?? []
	}

	public func navPathsBinding(for tab: TabPath) -> Binding<[NavPath]> {
		Binding(
			get: { self.navPaths(for: tab) },
			set: { newValue in
				self.routes[tab] = newValue
			}
		)
	}

	public func tabPathBinding() -> Binding<TabPath> {
		Binding(
			get: { self.selectedTab },
			set: { self.selectedTab = $0 }
		)
	}

	public func reset() {
		routes.forEach { key, value in
			routes[key] = []
		}
		selectedTab = .inbox
	}
}

extension Router {
	@ObservationIgnored
	fileprivate var currentNavPaths: [NavPath] {
		navPaths(for: selectedTab)
	}
}

extension Router {
	public func selectTab(_ newValue: TabPath) {
		guard selectedTab != newValue else { return }
		selectedTab = newValue
	}

	public func visiblePath() -> NavPath? {
		navPaths(for: selectedTab).last
	}

	public func pushToNav(_ path: NavPath) {
		var paths = navPaths(for: selectedTab)
		if let index = paths.firstIndex(where: { $0.id == path.id }) {
			paths = Array(paths[...index])
			routes[selectedTab] = paths
			return
		}
		paths.append(path)
		routes[selectedTab] = paths
	}

	public func pop() {
		navPathsBinding(for: selectedTab).wrappedValue.removeLast()
	}

	public func popToRoot() {
		navPathsBinding(for: selectedTab).wrappedValue = []
	}

	public func presentModel(_ value: NavPath) {
		sheet = value
	}

	public func dismissModal() {
		sheet = nil
	}
}

extension Router {
	@MainActor
	private static var _shared: Router = .init(.inbox)

	@MainActor
	public static var shared: Router { _shared }
}
