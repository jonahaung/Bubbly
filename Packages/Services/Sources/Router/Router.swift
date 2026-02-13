import Combine
import Core
import Database
import SwiftUI
import XUI

@MainActor
@Observable
public class Router {
	private var allPaths: [TabPath: [NavPath]]
	public var selectedTab: TabPath
	public var sheet: NavPath?

	public init(_ selected: TabPath) {
		selectedTab = selected
		allPaths = {
			var dictionary: [TabPath: [NavPath]] = [:]
			for item in TabPath.allCases {
				dictionary[item] = []
			}
			return dictionary
		}()
	}

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

extension Router: @MainActor Equatable {
	public static func == (_: Router, _: Router) -> Bool {
		true
	}
}

private extension Router {
	@ObservationIgnored
	var currentNavPaths: [NavPath]? {
		allPaths[selectedTab]
	}
}

public extension Router {
	func toolBarVisibility() -> Visibility {
		currentNavPaths.isNilOrEmpty ? .automatic : .hidden
	}

	func selectTab(_ newValue: TabPath) {
		selectedTab = newValue
	}

	func visiblePath() -> NavPath {
		allPaths[selectedTab]?.last ?? .currentUserDetails
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
	static let shared: Router = .init(.contacts)
}
