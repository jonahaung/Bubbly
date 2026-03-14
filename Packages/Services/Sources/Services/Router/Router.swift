//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import SwiftUI
import XUI

@MainActor
@Observable
public final class Router: Sendable {

    private var allPaths: [TabPath: [NavPath]]
    public var selectedTab: TabPath
    public var sheet: NavPath?

    public init(_ selected: TabPath) {
        selectedTab = selected
        allPaths = Dictionary(
            uniqueKeysWithValues: TabPath.allCases.map { ($0, []) }
        )
    }

    public func navPaths(for tab: TabPath) -> [NavPath] {
        allPaths[tab] ?? []
    }

    public func navPathsBinding(for tab: TabPath) -> Binding<[NavPath]> {
        Binding(
            get: { self.allPaths[tab] ?? [] },
            set: { self.allPaths[tab] = $0 }
        )
    }

    public func tabPathBinding() -> Binding<TabPath> {
        Binding(
            get: { self.selectedTab },
            set: { self.selectedTab = $0 }
        )
    }
}

private extension Router {
    @ObservationIgnored
    var currentNavPaths: [NavPath]? {
        allPaths[selectedTab]
    }
}

public extension Router {

    func selectTab(_ newValue: TabPath) {
        guard selectedTab != newValue else { return }
        selectedTab = newValue
    }

    func visiblePath() -> NavPath {
        allPaths[selectedTab]?.last ?? .currentUserDetails
    }

    func pushToNav(_ path: NavPath) {

        if let index = allPaths[selectedTab]?.firstIndex(of: path),
           let array = allPaths[selectedTab] {
            allPaths[selectedTab] = Array(array[0...index])
            return
        }

        allPaths[selectedTab]?.append(path)
    }

    func pop() {
        allPaths[selectedTab]?.removeLast()
    }

    func popToRoot() {
        allPaths[selectedTab] = []
    }

    func presentModel(_ value: NavPath) {
        sheet = value
    }

    func dismissModal() {
        sheet = nil
    }
}

public extension Router {
    @MainActor
    private static var _shared: Router = .init(.inbox)

    @MainActor
    static var shared: Router { _shared }
}
