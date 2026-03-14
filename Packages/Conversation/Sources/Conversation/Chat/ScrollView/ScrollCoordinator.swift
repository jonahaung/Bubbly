//
//  ScrollCoordinator.swift
//  Conversation
//
//  Created by Aung Ko Min on 11/3/26.
//

import Core
import Database
import ImageLoader
import OSLog
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ScrollCoordinator: ErrorPresenter {

	@ObservationIgnored private var pendingScrollRequests = Deque<ScrollPositionItem>()
	@ObservationIgnored weak var delegate: ScrollCoordinatorDelegate?
	@ObservationIgnored private let reducer = ScrollReducer()
	@ObservationIgnored private let displayLink = DisplayLink(1)

	var scrollPosition = ScrollPosition(edge: .bottom)
	var scrollPositionBindable: Binding<ScrollPosition> {
		.init(get: { self.scrollPosition }, set: { _ in self.scrollPosition = .init() })
	}
	private(set) var state: State
	@ObservationIgnored private var ignoredState: State

	init() {
		let initialState = State(
			updateState: .initial,
			geometry: .empty,
			direction: .down,
			phase: .idle,
			isFirstResponder: false,
			visibleIDs: []
		)
		state = initialState
		ignoredState = initialState
		displayLink.onTargetReached = { [weak self] _ in
			guard let self else { return }
			if ignoredState.phase.isScrolling {
				displayLink.start()
			} else {
				if pendingScrollRequests.isEmpty {
					finalizeScrollUpdates()
				} else {
					scrollIfNeeded()
				}
			}
		}
	}
}

extension ScrollCoordinator {
	func isNear(_ edge: VerticalEdge) -> Bool {
		ignoredState.geometry.isNear(edge)
	}

	func updateStateUpdate(to newValue: ScrollViewUpdate) {
		ignoredState.updateState.update(to: newValue)
	}

	func updateState(is state: ScrollViewUpdate) -> Bool {
		ignoredState.updateState == state
	}
}

extension ScrollCoordinator {

	private var canLoadOlderMessages: Bool {
		delegate?
			.scrollCoordinator(
				self,
				shouldPaginateAt: .top
			) == true
	}

	private var canLoadNewerMessages: Bool {
		delegate?
			.scrollCoordinator(self, shouldPaginateAt: .bottom) == true
	}

	private var shouldAdjustWindow: Bool {
		delegate?.scrollCoordinatorShouldRemove(self) == true
	}

	func loadOlderMessagesIfNeeded() {
		delegate?.scrollCoordinator(self, paginateAt: .top)
	}

	private func loadNewerMessagesIfNeeded() {
		delegate?.scrollCoordinator(self, paginateAt: .bottom)
	}

	private func onScrollDirectionChanged(_ newValue: ScrollDirection) {
		pendingScrollRequests.removeAll()
	}
}

extension ScrollCoordinator {

	func send(_ intent: Intent) {
		if prepare(intent) {
			let effect = reducer.reduce(
				state: ignoredState,
				intent: intent,
				canLoadOlder: canLoadOlderMessages,
				canLoadNewer: canLoadNewerMessages,
				shouldAdjustWindow: shouldAdjustWindow
			)

			handle(effect)
		}
	}
}

extension ScrollCoordinator {
	private func prepare(_ intent: Intent) -> Bool {
		switch intent {
		case .onVisibilityChange(let visibility):
			switch visibility {
			case .visible:
				scroll(to: .edge(.bottom, properties: .notAnimated))
				ignoredState.updateState.setHasViewLoaded()
				displayLink.start()
			case .hidden, .automatic:
				break
			}
			return false
		case .onBottomBarFrameChage(let oldValue, let newValue):
			if newValue.height == oldValue.height && newValue.maxY != oldValue.maxY {
				ignoredState.isFirstResponder = newValue.maxY < oldValue.maxY
			}
			guard ignoredState.updateState.isNotUpdating else { return false }
			guard newValue.maxY < oldValue.maxY else { return false }
			guard ignoredState.geometry.scrolledPosition != .atBottom else { return false }
			let targetY = ignoredState.geometry.offsetY + oldValue.maxY - newValue.maxY
			if ignoredState.phase.isScrolling {
				enqueueScroll(to: .y(targetY, properties: .animated(.easeInOutExponential)))
			} else {
				scrollPosition = .init(y: targetY)
			}
			return false
		case .onScrollGeometryChange(let oldValue, let newValue):
			ignoredState.geometry = newValue
			ignoredState.direction = newValue.offsetY < oldValue.offsetY ? .up : .down
			return true
		case .onScrollPhaseChange(let oldValue, let newValue, _):
			ignoredState.phase = newValue
			displayLink.stop()
			switch newValue {
			case .idle:
				if ignoredState.updateState.isNotUpdating {
					ignoredState.direction = .none
					displayLink.start()
				}
			case .interacting:
				if ignoredState.updateState == .willEndUpdates {
					ignoredState.updateState.update(to: .notUpdating)
				}
				pendingScrollRequests.removeAll()
			case .decelerating:
				if oldValue == .interacting,
					ignoredState.direction == .up && ignoredState.isFirstResponder
				{
					Task { @MainActor in
						UIApplication.shared.endEditing()
					}
				}
			case .animating, .tracking:
				break
			}
			return false
		case .onScrollTargetVisibilityChange(let newValue):
			ignoredState.visibleIDs = newValue
			return false
		}
	}
	private func handle(_ effect: ScrollReducer.Effect) {
		switch effect {
		case .scroll(let item):
			performScroll(to: item)
		case .begingUpdate(let updates):
			begin(updates: updates)
		case .endUpdate(let updates, let item):
			if let item {
				performScroll(to: item)
			}
			end(updates: updates)
		case .finalizeScrollViewUpdates:
			displayLink.start()
		case .removePendingUpdates:
			pendingScrollRequests.removeAll()
		case .noAction:
			break
		}
	}

	func begin(updates: DataUpdate) {
		ignoredState.updateState.update(to: .willUpdate)
		switch updates {
		case .insert(let edge):
			delegate?.scrollCoordinator(self, paginateAt: edge)
		case .remove(let edge):
			delegate?.scrollCoordinator(self, removeAt: edge)
		case .reset:
			delegate?.scrollCoordinator(self, resetAt: .bottom)
		case .append(let id):
			ignoredState.updateState.update(to: .appendingItem(id))
		}
	}

	private func end(updates: DataUpdate) {
		switch updates {
		case .insert, .remove, .append:
			ignoredState.updateState.update(to: .notUpdating)
		case .reset:
			ignoredState.updateState.update(to: .notUpdating)
			enqueueScroll(
				to: .edge(.bottom, properties: .animated(.easeInOut(duration: 0.5)))
			)
		}
	}

	private func finalizeScrollUpdates() {
		print(ignoredState.geometry.offsetY)
		delegate?.scrollCoordinator(self, finalizeUpdate: state, newState: ignoredState)
		state = ignoredState
	}
}

extension ScrollCoordinator {
	func enqueueScroll(to newValue: ScrollPositionItem) {
		pendingScrollRequests.enqueue(newValue)
		displayLink.start(0.2)
	}

	private func scrollIfNeeded() {
		guard let newValue = pendingScrollRequests.dequeue() else {
			return
		}
		performScroll(to: newValue)
	}
	private func performScroll(to newValue: ScrollPositionItem) {
		switch newValue.properties {
		case .animated(let animation):
			let transaction = Transaction.withAnimation(animation) { [weak self] in
				guard let self else { return }
				displayLink.start()
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		case .notAnimated:
			let transaction = Transaction.withoutAnimation { [weak self] in
				guard let self else { return }
				displayLink.start()
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		case .scroll:
			let transaction = Transaction.scrollView { [weak self] in
				guard let self else { return }
				displayLink.start()
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		}
	}

	func scroll(to newValue: ScrollPositionItem) {
		switch newValue.position {
		case .y(let value):
			scrollPosition.scrollTo(y: value)
		case .id(let value):
			scrollPosition.scrollTo(id: value, anchor: .bottom)
		case .layoutID(let value):
			scrollPosition.scrollTo(id: value, anchor: .bottom)
		case .edge(let edge):
			switch edge {
			case .top:
				scrollPosition.scrollTo(edge: .top)
			case .bottom:
				scrollPosition.scrollTo(edge: .bottom)
			}
		}
	}
}
