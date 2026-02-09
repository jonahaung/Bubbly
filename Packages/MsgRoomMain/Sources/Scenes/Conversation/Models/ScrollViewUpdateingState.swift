//
//  ScrollViewUpdateingState.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 24/9/25.
//

import Foundation
import SwiftUI

enum ScrollViewUpdatingState {
	case initial, notLoading, resetting
	case insertingItems(_ edge: VerticalEdge)
	case removingItems(_ edge: VerticalEdge)
	case appendingItem(_ id: String)
}

extension ScrollViewUpdatingState: Equatable {
	static func == (lhs: ScrollViewUpdatingState, rhs: ScrollViewUpdatingState) -> Bool {
		switch (lhs, rhs) {
		case (.notLoading, .notLoading),
		     (.initial, .initial):
			true
		case let (.insertingItems(lhs), .insertingItems(rhs)):
			lhs == rhs
		case let (.removingItems(lhs), .removingItems(rhs)):
			lhs == rhs
		default:
			false
		}
	}
}

extension ScrollViewUpdatingState {
	var hasViewLoaded: Bool {
		self != .initial
	}

	var isUpdating: Bool {
		switch self {
		case .insertingItems, .removingItems, .appendingItem, .resetting:
			true
		default:
			false
		}
	}

	var isNotUpdating: Bool {
		!isUpdating
	}
}

enum ScrollingState {
	case scrolling, notScrolling
	var isScrolling: Bool {
		self == .scrolling
	}

	var isNotScrolling: Bool {
		self == .notScrolling
	}
}
