// © 2026 Aung Ko Min

import Core
import Database
import SwiftUI
import XUI

// MARK: - Route

public struct Route: Sendable, Hashable, Identifiable {
    public var tabPath: TabPath
    public var navPaths: [NavPath]
    public var id: TabPath {
        tabPath
    }
}

// MARK: - Router

@MainActor
@Observable
public final class Router {
    public var routes: [TabPath: [NavPath]] = [:]
    @ObservationIgnored
    public var selectedTab: TabPath
    public var sheet: NavPath? = nil

    public init(_ selected: TabPath) {
        selectedTab = selected
        for each in TabPath.allCases {
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
            },
        )
    }

    public func tabPathBinding() -> Binding<TabPath> {
        Binding(
            get: { self.selectedTab },
            set: { self.selectedTab = $0 },
        )
    }

    public func reset() {
        for (key, _) in routes {
            routes[key] = []
        }
        sheet = nil
        selectedTab = .inbox
    }
}

private extension Router {
    @ObservationIgnored
    var currentNavPaths: [NavPath] {
        navPaths(for: selectedTab)
    }
}

public extension Router {
    func selectTab(_ newValue: TabPath) {
        guard selectedTab != newValue else {
            return
        }

        selectedTab = newValue
    }

    func visiblePath() -> NavPath? {
        navPaths(for: selectedTab).last
    }

    func pushToNav(_ path: NavPath) {
        var paths = navPaths(for: selectedTab)
        if let index = paths.firstIndex(where: { $0.id == path.id }) {
            paths = Array(paths[...index])
            routes[selectedTab] = paths
            return
        }
        paths.append(path)
        routes[selectedTab] = paths
    }

    func pop() {
        navPathsBinding(for: selectedTab).wrappedValue.removeLast()
    }

    func popToRoot() {
        navPathsBinding(for: selectedTab).wrappedValue = []
    }

    func presentModel(_ value: NavPath) {
        sheet = value
    }

    func dismissModal() {
        sheet = nil
    }
}

extension Router {
    @MainActor
    private static var _shared: Router = .init(.inbox)

    @MainActor
    public static var shared: Router {
        _shared
    }
}
