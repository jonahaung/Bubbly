//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

	public var routes: [Route]
	@ObservationIgnored
	public var selectedTab: TabPath
	public var sheet: NavPath?
	public var toolbarVisibility: Visibility = .visible

	public init(_ selected: TabPath) {
		selectedTab = selected
		routes = TabPath.allCases.map { .init(tabPath: $0, navPaths: []) }
	}

	public func navPaths(for tab: TabPath) -> [NavPath] {
		routes.first(where: { $0.tabPath == tab })?.navPaths ?? []
	}

	public func navPathsBinding(for tab: TabPath) -> Binding<[NavPath]> {
		Binding(
			get: { self.navPaths(for: tab) },
			set: { newValue in
				if let index = self.routes.firstIndex(where: { $0.tabPath == tab }) {
					self.routes[index].navPaths = newValue
				}
			}
		)
	}

	public func tabPathBinding() -> Binding<TabPath> {
		Binding(
			get: { self.selectedTab },
			set: { self.selectedTab = $0 }
		)
	}
}

extension Router {
	@ObservationIgnored
	fileprivate var currentNavPaths: [NavPath] {
		routes.first(where: { $0.tabPath == selectedTab })?.navPaths ?? []
	}
}

extension Router {
	public func setTabBar(visibility: Visibility) {
		toolbarVisibility = visibility
	}
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
			navPathsBinding(for: selectedTab).wrappedValue = paths
			return
		}
		navPathsBinding(for: selectedTab).wrappedValue.append(path)
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
