//
//  NavRouter.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import Core
import Database
import SwiftUI

@MainActor
@Observable
public class NavRouter: Identifiable {
    public let id: TabPath

    public var navPath = [NavPath]()

    public init(_ tab: TabPath) {
        id = tab
    }

    public func push(_ path: NavPath) {
        if let index = navPath.firstIndex(of: path) {
            navPath = Array(navPath[0 ... index])
            return
        }
        navPath.append(path)
    }

    public func replace(_ paths: [NavPath]) {
        guard !navPath.isEmpty else { return }
        navPath = paths
    }

    public func pop() {
        guard navPath.isEmpty == false else { return }
        navPath.remove(at: 0)
    }

    public static func == (lhs: NavRouter, rhs: NavRouter) -> Bool {
        lhs.id == rhs.id
    }
}
