import SwiftUI
import XUI

struct ScrollState: Sendable {
	var updateState: ScrollViewUpdatingState
	var geometry: VScrollGeometry
	var direction: VerticalDirection
	var phase: ScrollPhase
	var isFirstResponder: Bool
	var visibleIDs: [String]

	init(
		updateState: ScrollViewUpdatingState = .initial,
		geometry: VScrollGeometry = .empty,
		direction: VerticalDirection = .down,
		phase: ScrollPhase = .idle,
		isFirstResponder: Bool = false,
		visibleIDs: [String] = []
	) {
		self.updateState = updateState
		self.geometry = geometry
		self.direction = direction
		self.phase = phase
		self.isFirstResponder = isFirstResponder
		self.visibleIDs = visibleIDs
	}
}

extension ScrollState: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.updateState == rhs.updateState &&
		lhs.direction == rhs.direction &&
		lhs.phase == rhs.phase &&
		lhs.isFirstResponder == rhs.isFirstResponder
	}
}
