import SwiftUI
import XUI

struct ScrollState: Sendable, Equatable {
	var updateState: ScrollViewUpdatingState
	var geometry: VScrollGeometry
	var direction: VerticalEdge
	var phase: ScrollPhase
	var isFirstResponder: Bool
	var visibleIDs: [String]

	init(
		updateState: ScrollViewUpdatingState = .initial,
		geometry: VScrollGeometry = .empty,
		direction: VerticalEdge = .bottom,
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
