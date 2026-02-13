import Foundation
import SwiftUI

struct ScrollReducer {
	mutating func reduce(state: inout ScrollState,
	                     action: ScrollAction,
	                     canLoadOlder: Bool,
	                     canLoadNewer: Bool) -> ScrollEffect
	{
		switch action {
		case .viewLoaded:
			state.updateState = .notLoading
			return .none

		case let .phaseChanged(_, newPhase, context):
			state.phase = newPhase
			state.scrollGeometry = VScrollGeometry(context.geometry)
			state.scrolledPosition = context.geometry.scrolledPosition
			return .none

		case let .geometryChanged(old, new):
			return reduceGeometry(
				state: &state,
				old: old,
				new: new,
				canLoadOlder: canLoadOlder,
				canLoadNewer: canLoadNewer
			)

		case let .inputAccessoryChanged(old, new):
			return reduceInputAccessory(
				state: &state,
				old: old,
				new: new
			)
		}
	}
}

private extension ScrollReducer {
	func reduceGeometry(state: inout ScrollState,
	                    old: VScrollGeometry,
	                    new: VScrollGeometry,
	                    canLoadOlder: Bool,
	                    canLoadNewer: Bool) -> ScrollEffect
	{
		state.scrollGeometry = new

		guard state.updateState.hasViewLoaded else {
			return .none
		}

		if state.updateState.isUpdating {
			return handleUpdating(state: &state, old: old, new: new)
		}

		return handleIdle(
			state: &state,
			old: old,
			new: new,
			canLoadOlder: canLoadOlder,
			canLoadNewer: canLoadNewer
		)
	}
}

private extension ScrollReducer {
	func handleIdle(state: inout ScrollState,
	                old: VScrollGeometry,
	                new: VScrollGeometry,
	                canLoadOlder: Bool,
	                canLoadNewer: Bool) -> ScrollEffect
	{
		guard old.contentHeight == new.contentHeight else {
			return .none
		}

		guard state.updateState.isNotUpdating else {
			return .none
		}

		let direction: VerticalEdge =
			new.offsetY > old.offsetY ? .bottom : .top

		state.scrollDirection = direction

		switch direction {
		case .top:
			if new.offsetY < -new.topInset, canLoadOlder {
				state.updateState = .insertingItems(.top)
				return .loadOlder
			}

		case .bottom:
			let threshold = bottomThreshold(new)
			if new.offsetY >= threshold, canLoadNewer {
				state.updateState = .insertingItems(.bottom)
				return .loadNewer
			}
		}

		return .none
	}
}

private extension ScrollReducer {
	func handleUpdating(state: inout ScrollState,
	                    old: VScrollGeometry,
	                    new: VScrollGeometry) -> ScrollEffect
	{
		if old.contentHeight == new.contentHeight {
			return .none
		}

		let difference = new.contentHeight - old.contentHeight

		switch state.updateState {
		case .insertingItems(.top):
			let offsetY = new.offsetY + difference + new.topInset
			state.updateState = .notLoading
			return .scrollToOffset(offsetY, animated: false, duration: nil)

		case .insertingItems(.bottom):
			state.updateState = .notLoading
			return .scrollToBottom(animated: true, duration: 0.25)

		case .appendingItem:
			state.updateState = .notLoading
			return .scrollToOffset(
				new.bottomMostOffset,
				animated: true,
				duration: 0.3
			)

		case .resetting:
			state.updateState = .notLoading
			return .scrollToBottom(animated: false, duration: nil)

		default:
			return .none
		}
	}
}

private extension ScrollReducer {
	func reduceInputAccessory(state: inout ScrollState,
	                          old: CGRect,
	                          new: CGRect) -> ScrollEffect
	{
		guard state.updateState.hasViewLoaded else {
			return .none
		}

		guard old.height != new.height else {
			return .none
		}

		if state.scrolledPosition == .atBottom {
			return .none
		}

		let targetY =
			state.scrollGeometry.offsetY
				+ (old.minY - new.minY)
				+ state.scrollGeometry.topInset

		return .scrollToOffset(targetY, animated: true, duration: 0.2)
	}
}

private extension ScrollReducer {
	func bottomThreshold(_ geometry: VScrollGeometry) -> CGFloat {
		let extraSpace = geometry.boundsHeight / 2

		return geometry.contentHeight
			- geometry.boundsHeight
			- geometry.topInset
			- extraSpace
	}
}
