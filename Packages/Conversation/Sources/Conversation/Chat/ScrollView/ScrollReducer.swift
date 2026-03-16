//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Foundation
import SwiftUI
import XUI

struct ScrollReducer {

	typealias State = ScrollCoordinator.State
	typealias Intent = ScrollCoordinator.Intent
	typealias DataUpdate = ScrollCoordinator.DataUpdate

	enum Effect: Equatable {
		case scroll(item: ScrollPositionItem)
		case begingUpdate(_ updates: DataUpdate)
		case endUpdate(_ updates: DataUpdate, scrollItem: ScrollPositionItem?)
		case finalizeScrollViewUpdates
		case removePendingUpdates
		case noAction
	}
}

extension ScrollReducer {
	func reduce(
		state: State,
		intent: Intent,
		canLoadOlder: Bool,
		canLoadNewer: Bool,
		shouldAdjustWindow: Bool
	) -> Effect {
		switch intent {
		case .onScrollGeometryChange(let oldValue, let newValue):
			return reduceGeometry(
				state: state,
				oldValue: oldValue,
				newValue: newValue,
				canLoadOlder: canLoadOlder,
				canLoadNewer: canLoadNewer,
				shouldAdjustWindow: shouldAdjustWindow
			)
		default:
			return .noAction
		}
	}
}

extension ScrollReducer {
	private func reduceGeometry(
		state: State,
		oldValue: VScrollGeometry,
		newValue: VScrollGeometry,
		canLoadOlder: Bool,
		canLoadNewer: Bool,
		shouldAdjustWindow: Bool
	) -> Effect {

		guard state.updateState.hasViewLoaded else {
			return .noAction
		}

		if state.updateState.isUpdating {
			return handleUpdating(state: state, oldValue: oldValue, newValue: newValue)
		}
		if oldValue.contentHeight == newValue.contentHeight {
			guard state.updateState.isNotUpdating, state.phase == .decelerating,
				  oldValue.contentHeight == newValue.contentHeight
			else {
				return .noAction
			}

			return paginateIfNeeded(
				state,
				newValue,
				canLoadOlder,
				canLoadNewer,
				shouldAdjustWindow: shouldAdjustWindow
			)
		} else {
			return .noAction
		}

	}

	private func paginateIfNeeded(
		_ state: ScrollReducer.State,
		_ newValue: VScrollGeometry,
		_ canLoadOlder: Bool,
		_ canLoadNewer: Bool,
		shouldAdjustWindow: Bool
	) -> ScrollReducer.Effect {
		if state.direction == .up, newValue.canPaginate(at: .top) {
			if canLoadOlder {
				return .begingUpdate(
					shouldAdjustWindow ? .remove(edge: .bottom) : .insert(edge: .top)
				)
			}
			if shouldAdjustWindow {
				return .begingUpdate(.remove(edge: .bottom))
			}
			return .noAction
		}
		if state.direction == .down, newValue.canPaginate(at: .bottom) {
			if canLoadNewer {
				return .begingUpdate(
					shouldAdjustWindow ? .remove(edge: .top) : .insert(edge: .bottom)
				)
			}

			if shouldAdjustWindow {
				return .begingUpdate(.remove(edge: .top))
			}
			return .noAction

		}
		return .noAction
	}

	private func handleUpdating(
		state: State,
		oldValue: VScrollGeometry,
		newValue: VScrollGeometry
	) -> Effect {
		let difference = newValue.contentHeight - oldValue.contentHeight
		switch state.updateState {
		case .resetting:
			let offsetY = newValue.offsetY + difference + (newValue.offsetY - oldValue.offsetY)
			if difference == 0 {
				return .scroll(item: .y(newValue.offsetY))
			} else {
				return .endUpdate(.reset, scrollItem: .y(offsetY))
			}
		case .insertingItems(let edge):
			switch edge {
			case .top:
				guard difference != 0 else {
					return .scroll(item: .y(newValue.offsetY, properties: .scroll))
				}
				let offsetY = newValue.offsetY + difference + (newValue.offsetY - oldValue.offsetY)
				return .endUpdate(.insert(edge: edge), scrollItem: .y(offsetY, properties: .scroll))
			case .bottom:
				return .endUpdate(.insert(edge: edge), scrollItem: nil)
			}
		case .removingItems(let edge):
			
			switch edge {
			case .top:
				guard difference != 0 else {
					return .scroll(item: .y(newValue.offsetY))
				}
				let offsetY = newValue.offsetY + difference + (newValue.offsetY - oldValue.offsetY)
				return .endUpdate(
					.remove(edge: edge),
					scrollItem: .y(offsetY, properties: .scroll)
				)
			case .bottom:
				return .endUpdate(.remove(edge: .bottom), scrollItem: nil)
			}
		case .appendingItem(let id):
			return .endUpdate(
				.append(id: id),
				scrollItem: .id(id, properties: .animated(.easeOutExponential(duration: 0.3)))
			)
		default:
			return .noAction
		}
	}
}
