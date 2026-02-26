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
		case .onScrollPhaseChange:
			return .noAction
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
		
		if state.updateState.isUpdating, oldValue.contentHeight != newValue.contentHeight {
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

		guard state.updateState.isNotUpdating, state.phase == .decelerating, oldValue.contentHeight == newValue.contentHeight else {
			return .noAction
		}
		if canLoadOlder, newValue.offsetY < newValue.boundsHeight/2 {

			return .begingUpdate(.removeItems(edge: .bottom))
		}
		if canLoadNewer, newValue
			.offsetY+(newValue.boundsHeight + newValue.boundsHeight/2) > newValue.contentHeight {
			return .begingUpdate(.insertItems(edge: .bottom))
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
			return .endUpdate(.reseting, scrollItem: .snapToBottom())
		case let .insertingItems(edge):
			guard difference != 0 else {
				return .noAction
			}
			switch edge {
			case .top:
				let offsetY = newValue.offsetY + difference + (newValue.offsetY - oldValue.offsetY)
				return .endUpdate(.insertItems(edge: .top), scrollItem: .y(offsetY))
			case .bottom:
				return .endUpdate(.insertItems(edge: .bottom), scrollItem: nil)
			}
		case let .removingItems(edge):
			switch edge {
			case .top:
				return .noAction
			case .bottom:
				return .endUpdate(
					.removeItems(edge: .bottom),
					scrollItem: .y(newValue.offsetY + (newValue.offsetY - oldValue.offsetY))
				)
			}
		case .appendingItem(_):
			state.updateState.update(to: .notUpdating)
			return .scroll(item: .y(newValue.bottomMostOffset, animation: .snappy))
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
