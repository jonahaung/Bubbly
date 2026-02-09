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
	private var allPaths: [TabPath: [NavPath]] = {
		var dictionary: [TabPath: [NavPath]] = [:]
		for item in TabPath.allCases {
			dictionary[item] = []
		}
		return dictionary
	}()

	public var selectedTab: TabPath = .inbox
	public var sheet: NavPath?
	@ObservationIgnored
	public var currentNavPaths: [NavPath]? {
		allPaths[selectedTab]
	}

	@ObservationIgnored
	public var visiblePath: NavPath {
		allPaths[selectedTab]?.last ?? .currentUserDetails
	}

	public init() {}

	public func navPaths(for tab: TabPath) -> [NavPath] {
		allPaths[tab] ?? []
	}

	public func navPathsBinding(for tab: TabPath) -> Binding<[NavPath]> {
		.init(get: {
			self.navPaths(for: tab)
		}, set: { newValue in
			self.allPaths[tab] = newValue
		})
	}
}

public extension Router {
	func selectTab(_ newValue: TabPath) {
		selectedTab = newValue
	}

	func pushToNav(_ path: NavPath) {
		Task(priority: .background) {
			var allPaths = self.allPaths
			if let index = allPaths[selectedTab]?.firstIndex(of: path),
			   let array = allPaths[selectedTab]
			{
				allPaths[selectedTab] = Array(array[0 ... index])
				return
			}
			allPaths[selectedTab]?.append(path)
			Task { @MainActor in
				self.allPaths = allPaths
			}
		}
	}

	func pop() {
		allPaths[selectedTab] = allPaths[selectedTab]?.dropLast()
	}

	func popToRoot() {
		allPaths[selectedTab] = []
	}

	func presnetModel(_ value: NavPath) {
		sheet = value
	}

	func dismissModal() {
		sheet = nil
	}
}

public extension Router {
	/// Shared instance for app-wide navigation
	static let shared: Router = .init()
}
