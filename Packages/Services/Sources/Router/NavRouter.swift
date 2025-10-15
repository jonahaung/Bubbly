//
//  NavRouter.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

import SwiftUI
import Database
import Core

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
			navPath = Array(navPath[0...index])
			return
		}
		navPath.append(path)
	}
	public func replace(_ paths: [NavPath]) {
		navPath = paths
	}
	public static func == (lhs: NavRouter, rhs: NavRouter) -> Bool {
		lhs.id == rhs.id
	}
}
