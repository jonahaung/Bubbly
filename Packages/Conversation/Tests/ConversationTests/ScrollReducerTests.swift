//
//  ScrollReducerTests.swift
//  Conversation
//
//  Created by Aung Ko Min on 5/4/26.
//


import Testing
import SwiftUI
@testable import ConversationTestingSupport

struct ScrollReducerTests {

	private let reducer = ScrollReducer()

	// MARK: - Helpers

	private func makeState(
		phase: ConversationTestingSupport.ScrollPhase = .interacting,
		updateState: ScrollCoordinator.ScrollViewUpdate = .didEndUpdates
	) -> ScrollCoordinator.State {
		.init(
			updateState: updateState,
			geometry: geo(offsetY: 200),
			phase: phase,
			isFirstResponder: false,
			scrolledPosition: .atBottom
		)
	}

	private func geo(
		offsetY: CGFloat,
		contentHeight: CGFloat = 1000,
		boundsHeight: CGFloat = 500
	) -> VScrollGeometry {
		.init(
			contentHeight: contentHeight,
			boundsHeight: boundsHeight,
			offsetY: offsetY,
			topInset: 50,
			bottomInset: 50
		)
	}

	// MARK: - No Action

	@Test
	func noAction_whenOffsetUnchanged() {
		let state = makeState()
		let g = geo(offsetY: 100)

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(g, g),
			canLoadOlder: true,
			canLoadNewer: true,
			shouldAdjustWindow: false
		)

		#expect(effect == .noAction)
	}

	@Test
	func noAction_whenNotInteracting() {
		let state = makeState(phase: ConversationTestingSupport.ScrollPhase.idle)
		let old = geo(offsetY: 100)
		let new = geo(offsetY: 50)

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(old, new),
			canLoadOlder: true,
			canLoadNewer: true,
			shouldAdjustWindow: false
		)

		#expect(effect == .noAction)
	}

	// MARK: - Pagination (Down → Older)

	@Test
	func beginUpdate_insertTop_whenScrollDownAndCanLoadOlder() {
		let state = makeState()
		let old = geo(offsetY: 100)
		let new = geo(offsetY: 0) // near threshold

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(old, new),
			canLoadOlder: true,
			canLoadNewer: false,
			shouldAdjustWindow: false
		)

		#expect(effect == .begingUpdate(ScrollCoordinator.DataUpdate.insert(edge: .top)))
	}

	@Test
	func beginUpdate_removeBottom_whenAdjustWindow() {
		let state = makeState()
		let old = geo(offsetY: 100)
		let new = geo(offsetY: 0)

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(old, new),
			canLoadOlder: false,
			canLoadNewer: false,
			shouldAdjustWindow: true
		)

		#expect(effect == .begingUpdate(ScrollCoordinator.DataUpdate.remove(edge: .bottom)))
	}

	// MARK: - Pagination (Up → Newer)

	@Test
	func beginUpdate_insertBottom_whenScrollUpAndAtBottom() {
		let state = makeState()
		let old = geo(offsetY: 400)
		let new = geo(offsetY: 600, contentHeight: 1000, boundsHeight: 400) // at bottom

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(old, new),
			canLoadOlder: false,
			canLoadNewer: true,
			shouldAdjustWindow: false
		)

		#expect(effect == .begingUpdate(ScrollCoordinator.DataUpdate.insert(edge: .bottom)))
	}

	@Test
	func noAction_whenScrollUpButNotAtBottom() {
		let state = makeState()
		let old = geo(offsetY: 100)
		let new = geo(offsetY: 200)

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(old, new),
			canLoadOlder: false,
			canLoadNewer: true,
			shouldAdjustWindow: false
		)

		#expect(effect == .noAction)
	}

	// MARK: - Updating State

	@Test
	func endUpdate_insertTop_withScrollAdjustment() {
		let state = makeState(
			updateState: ScrollCoordinator.ScrollViewUpdate.insertingItems(.top)
		)
		let old = geo(offsetY: 100, contentHeight: 1000)
		let new = geo(offsetY: 120, contentHeight: 1100)

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(old, new),
			canLoadOlder: false,
			canLoadNewer: false,
			shouldAdjustWindow: false
		)

		switch effect {
		case .endUpdate(.insert(edge: .top), let scrollItem):
			#expect(scrollItem != nil)
		default:
			#expect(Bool(false))
		}
	}

	@Test
	func endUpdate_removeBottom_withoutScrollItem() {
		let state = makeState(
			updateState: ScrollCoordinator.ScrollViewUpdate.removingItems(.bottom)
		)
		let old = geo(offsetY: 100, contentHeight: 1000)
		let new = geo(offsetY: 100, contentHeight: 900)

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(old, new),
			canLoadOlder: false,
			canLoadNewer: false,
			shouldAdjustWindow: false
		)

		switch effect {
		case .endUpdate(.remove(edge: .bottom), let scrollItem):
			#expect(scrollItem == nil)
		default:
			#expect(Bool(false))
		}
	}

	@Test
	func endUpdate_appendItem_returnsAnimatedScroll() {
		let state = makeState(
			updateState: ScrollCoordinator.ScrollViewUpdate.appendingItem("1")
		)
		let old = geo(offsetY: 100, contentHeight: 1000)
		let new = geo(offsetY: 120, contentHeight: 1100)

		let effect = reducer.reduce(
			state: state,
			intent: .onScrollGeometryChange(old, new),
			canLoadOlder: false,
			canLoadNewer: false,
			shouldAdjustWindow: false
		)

		switch effect {
		case .endUpdate(.append(id: "1"), let scrollItem):
			#expect(scrollItem != nil)
		default:
			#expect(Bool(false))
		}
	}
}
