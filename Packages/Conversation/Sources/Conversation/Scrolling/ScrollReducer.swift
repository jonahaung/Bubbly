import Foundation
import SwiftUI

struct ScrollReducer {
	func reduce(state: inout ScrollState,
				intent: ScrollViewIntent,
	                     canLoadOlder: Bool,
	                     canLoadNewer: Bool) -> ScrollEffect {
		switch intent {
		case .onVisibilityChange(let visibility):
			switch visibility {
			case .visible, .automatic:
				return .scroll(item: .edge(.bottom))
			case .hidden:
				return .noAction
			}
		case let .onScrollGeometryChange(oldValue, newValue):
			return reduceGeometry(
				state: &state,
				oldValue: oldValue,
				newValue: newValue,
				canLoadOlder: canLoadOlder,
				canLoadNewer: canLoadNewer)
		case let .onScrollPhaseChange(oldValue, newValue, _):
			switch newValue {
			case .idle:
				if state.updateState.isUpdating {
					return .noAction
				}
				return .finalizeScrollViewUpdates
			case .tracking:
				return .noAction
			case .interacting:
				return .removePendingUpdates
			case .decelerating:
				if oldValue == .interacting, state.direction == .top && state.isFirstResponder {
					MainActor.assumeIsolated {
						UIApplication.shared.endEditing()
					}
				}
				return .noAction
			case .animating:
				return .noAction
			}
		case .onScrollTargetVisibilityChange:
			return .noAction
		case let .onBottomBarFrameChage(oldValue, newValue):
			return reduceInputAccessory(state: &state, oldValue: oldValue, newValue: newValue)
		}
	}
}

private extension ScrollReducer {
	func reduceGeometry(state: inout ScrollState,
						oldValue: VScrollGeometry,
						newValue: VScrollGeometry,
	                    canLoadOlder: Bool,
	                    canLoadNewer: Bool) -> ScrollEffect {

		guard state.updateState.hasViewLoaded else {
			return .noAction
		}
		
		if state.updateState.isUpdating {
			return handleUpdating(state: &state, oldValue: oldValue, newValue: newValue)
		}

		return handleIdle(
			state: &state,
			oldValue: oldValue,
			newValue: newValue,
			canLoadOlder: canLoadOlder,
			canLoadNewer: canLoadNewer
		)
	}
}

private extension ScrollReducer {
	func handleIdle(state: inout ScrollState,
					oldValue: VScrollGeometry,
					newValue: VScrollGeometry,
	                canLoadOlder: Bool,
	                canLoadNewer: Bool) -> ScrollEffect
	{
		if canLoadOlder, newValue.offsetY < newValue.boundsHeight/2 {
			state.updateState.update(to: .insertingItems(.top))
			return .insertItems(edge: .top)
		}
		if canLoadNewer, newValue
			.offsetY+(newValue.boundsHeight + newValue.boundsHeight/2) > newValue.contentHeight {
			state.updateState.update(to: .insertingItems(.bottom))
			return .insertItems(edge: .bottom)
		}
		return .noAction
	}
}

private extension ScrollReducer {
	func handleUpdating(state: inout ScrollState,
						oldValue: VScrollGeometry,
						newValue: VScrollGeometry) -> ScrollEffect {
		let difference = newValue.contentHeight - oldValue.contentHeight

		switch state.updateState {
		case .initial:
			break
		case .notUpdating:
			break
		case .resetting:
			state.updateState.update(to: .notUpdating)
			return .scroll(item: .snapToBottom())
		case let .insertingItems(edge):
			switch edge {
			case .top:
				guard difference != 0 else {
					state.updateState.startUpdating()
					return .noAction
				}
				state.updateState.startUpdating()
				let offsetY = newValue.offsetY + difference
				return .scroll(item: .y(offsetY))
			case .bottom:
				state.updateState.startUpdating()
				return .noAction
			}
		case let .removingItems(edge):
			switch edge {
			case .top:
				return .noAction
			case .bottom:
				return .scroll(item: .y(newValue.boundsHeight/2))
			}
		case .appendingItem:
			state.updateState.update(to: .notUpdating)
			return .scroll(item: .y(newValue.bottomMostOffset, animation: .interpolatingSpring))
		case .updating:
			if difference == 0 {
				state.updateState.endUpdating()
			}
			return .noAction
		}
		return .noAction
	}
}

private extension ScrollReducer {
	func reduceInputAccessory(state: inout ScrollState,
							  oldValue: CGRect,
							  newValue: CGRect) -> ScrollEffect
	{

		if !state.updateState.hasViewLoaded {
			return .scroll(item: .edge(.bottom))
		}
		return .noAction
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
