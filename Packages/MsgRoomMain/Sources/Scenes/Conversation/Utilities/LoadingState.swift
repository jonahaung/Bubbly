//
//  LoadingState.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 24/9/25.
//

import Foundation
import SwiftUI

enum LoadingState {
	case notLoading, previous, next, restricted
	case adjustingWindows(_ position: VerticalEdge)
}
extension LoadingState: Equatable {
	static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
		switch (lhs, rhs) {
		case (.notLoading, .notLoading),
			(.previous, .previous),
			(.next, .next),
			(.restricted, .restricted):
			return true

		case let (.adjustingWindows(a), .adjustingWindows(b)):
			return a == b
		default:
			return false
		}
	}
}

extension LoadingState {
	var isLoading: Bool {
		switch self {
		case .previous, .next, .adjustingWindows:
			return true
		default:
			return false
		}
	}

	var isNotLoading: Bool { !isLoading }

	var isLoadingNext: Bool {
		if case .next = self { return true }
		return false
	}

	var isLoadingPrevious: Bool {
		if case .previous = self { return true }
		return false
	}

	var isRestricted: Bool {
		if case .restricted = self { return true }
		return false
	}

	var canLoadPrevious: Bool {
		!isLoading && self != .restricted
	}
}
