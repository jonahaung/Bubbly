//
//  ScrollViewUpdatingState.swift
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
	case appendingItem(_ id: String, index: Int)
}
extension ScrollViewUpdatingState: Equatable {
	static func == (lhs: ScrollViewUpdatingState, rhs: ScrollViewUpdatingState) -> Bool {
		switch (lhs, rhs) {
		case (.notLoading, .notLoading),
			(.initial, .initial):
			return true
		case let (.insertingItems(a), .insertingItems(b)):
			return a == b
		case let (.removingItems(a), .removingItems(b)):
			return a == b
		default:
			return false
		}
	}
}

extension ScrollViewUpdatingState {
	var hasViewLoaded: Bool {
		self != .initial
	}
	var isUpdating: Bool {
		switch self {
		case .insertingItems, .removingItems, .resetting, .appendingItem:
			return true
		default:
			return false
		}
	}

	var isNotUpdating: Bool { !isUpdating }
}
