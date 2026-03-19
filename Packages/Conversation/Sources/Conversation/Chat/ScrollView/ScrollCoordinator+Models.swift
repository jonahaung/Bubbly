//
//  ScrollCoordinator+Models.swift
//  Conversation
//
//  Created by Aung Ko Min on 11/3/26.
//

import Database
import SwiftUI
import XUI

extension ScrollCoordinator {
	enum ScrollDirection: Sendable, Hashable {
		case up, down, none
	}
	struct State: Sendable, Hashable {
		var updateState: ScrollViewUpdate
		var geometry: VScrollGeometry
		var direction: ScrollDirection
		var phase: ScrollPhase
		var isFirstResponder: Bool
		var scrolledPosition = ScrolledPosition.atBottom
	}

	enum Intent {
		case onVisibilityChange(visibility: Visibility)
		case onScrollGeometryChange(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry)
		case onScrollPhaseChange(
			_ oldValue: ScrollPhase,
			_ newPhase: ScrollPhase,
			context: ScrollPhaseChangeContext
		)
		case onBottomBarFrameChage(_ oldValue: CGRect, _ newValue: CGRect)
	}

	enum DataUpdate: Sendable, Hashable {
		case insert(edge: VerticalEdge)
		case remove(edge: VerticalEdge)
		case reset
		case append(id: String)
	}

	enum ScrollViewUpdate: Hashable {
		case initial, notUpdating, resetting, willUpdate, willEndUpdates
		case insertingItems(_ edge: VerticalEdge)
		case removingItems(_ edge: VerticalEdge)
		case appendingItem(_ id: String)

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
			guard self != newValue else {
				return
			}
			self = newValue
		}

		mutating func setHasViewLoaded() {
			guard self == .initial else {
				return
			}
			self = .notUpdating
		}
	}
}
