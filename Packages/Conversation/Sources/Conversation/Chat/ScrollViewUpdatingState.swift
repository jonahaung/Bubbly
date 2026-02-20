import Foundation
import SwiftUI

enum ScrollViewUpdatingState: Equatable {
	case initial, notUpdating, updating, resetting
	case insertingItems(_ edge: VerticalEdge)
	case removingItems(_ edge: VerticalEdge)
	case appendingItem(_ id: String)
}

extension ScrollViewUpdatingState {
	var hasViewLoaded: Bool {
		self != .initial
	}

	var isUpdating: Bool {
		self != .notUpdating
	}

	var isNotUpdating: Bool {
		!isUpdating
	}
	mutating func update(to newValue: Self) {
		self = newValue
	}
	mutating func setHasViewLoaded() {
		self = .notUpdating
	}
	mutating func endUpdating() {
		guard self == .updating else {
			return
		}
		self = .notUpdating
	}
	mutating func startUpdating() {
		self = .updating
	}
}
