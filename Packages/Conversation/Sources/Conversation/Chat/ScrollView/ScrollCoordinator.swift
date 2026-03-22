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

	private var scrollPosition = ScrollPosition()

	@ObservationIgnored
	private var pendingScrollRequests = Deque<ScrollPositionItem>()
	@ObservationIgnored
	weak var delegate: ScrollCoordinatorDelegate?
	@ObservationIgnored
	private let reducer = ScrollReducer()
	@ObservationIgnored
	private let displayLink = DisplayLink(0.5)
	@ObservationIgnored
	var scrollPositionBindable: Binding<ScrollPosition> {
		.init(
			get: { [self] in
				return scrollPosition
			},
			set: { [self] newValue in
				scrollPosition = .init()
			}
		)
	}
	@ObservationIgnored
	private(set) var state: State
	@ObservationIgnored
	private(set) var ignoredState: State

	init() {
		let initialState = State(
			updateState: .initial,
			geometry: .empty,
			direction: .down,
			phase: .idle,
			isFirstResponder: false
		)
		state = initialState
		ignoredState = initialState
		displayLink.onTargetReached = { [weak self] _ in
			guard let self else { return }
			if ignoredState.phase.isScrolling {
				queueToFinalizeUpdates()
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
	func updatedState(is state: ScrollViewUpdate) -> Bool {
		ignoredState.updateState == state
	}
	func handleResetData() {
		guard ignoredState.updateState.isNotUpdating else {
			return
		}
		begin(updates: .reset)
	}
}

extension ScrollCoordinator {
	func send(_ intent: Intent) {

		func shouldPaginate(at edge: VerticalEdge) -> Bool {
			delegate?
				.scrollCoordinator(self, shouldPaginateAt: edge) == true
		}
		var shouldAdjustWindow: Bool {
			delegate?.scrollCoordinatorShouldRemove(self) == true
		}

		if prepare(intent) {
			let effect = reducer.reduce(
				state: ignoredState,
				intent: intent,
				canLoadOlder: shouldPaginate(at: .top),
				canLoadNewer: shouldPaginate(at: .bottom),
				shouldAdjustWindow: shouldAdjustWindow
			)

			handleEffect(effect)
		}
	}
	private func prepare(_ intent: Intent) -> Bool {
		switch intent {
		case .onVisibilityChange(let visibility):
			switch visibility {
			case .visible, .automatic:
				performScroll(to: .edge(.bottom, properties: .scroll))
				ignoredState.updateState.setHasViewLoaded()
			case .hidden:
				displayLink.stop()
				print(ignoredState.geometry.offsetY)
			}
			return false
		case .onBottomBarFrameChage(let oldValue, let newValue):
			guard state.updateState.hasViewLoaded else { return false }
			if newValue.height == oldValue.height && newValue.maxY != oldValue.maxY {
				ignoredState.isFirstResponder = newValue.maxY < oldValue.maxY
			}
			guard ignoredState.geometry.scrolledPosition != .atBottom else { return false }
			if ignoredState.isFirstResponder {
				guard newValue.height == oldValue.height, newValue.maxY < oldValue.maxY else {
					return false
				}
				let difference = oldValue.maxY - newValue.maxY
				let targetY = min(ignoredState.geometry.bottomMostOffset, ignoredState.geometry.offsetY + difference)
				if ignoredState.phase.isScrolling {
					enqueueScroll(to: .y(targetY, properties: .animated(.easeInOutExponential)))
				} else {
					performScroll(to: .y(targetY, properties: .notAnimated))
				}
			}
			return false
		case .onScrollGeometryChange(let oldValue, let newValue):
			ignoredState.geometry = newValue
			guard state.updateState.hasViewLoaded else { return false }
			ignoredState.direction = newValue.offsetY < oldValue.offsetY ? .up : .down
			return true
		case .onScrollPhaseChange(let oldValue, let newValue, _):
			guard state.updateState.hasViewLoaded else { return false }
			ignoredState.phase = newValue

			if ignoredState.updateState == .willEndUpdates {
				ignoredState.updateState.update(to: .didEndUpdates)
			}
			guard ignoredState.updateState.isNotUpdating else { return false }
			switch newValue {
			case .idle:
				ignoredState.direction = .none
				queueToFinalizeUpdates()
			case .interacting:
				displayLink.stop()
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
		}
	}
	private func handleEffect(_ effect: ScrollReducer.Effect) {
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
			queueToFinalizeUpdates()
		case .removePendingUpdates:
			pendingScrollRequests.removeAll()
		case .noAction:
			break
		}
	}

	private func begin(updates: DataUpdate) {
		ignoredState.updateState.update(to: .willBeginUpdates)
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
		case .insert(let edge):
			if edge == .top {
				ignoredState.updateState.update(to: .willEndUpdates)
			} else {
				ignoredState.updateState.update(to: .didEndUpdates)
			}
		case .remove, .append:
			ignoredState.updateState.update(to: .didEndUpdates)
		case .reset:
			ignoredState.updateState.update(to: .didEndUpdates)
			enqueueScroll(
				to: .edge(.bottom, properties: .animated(.easeInOut(duration: 0.5)))
			)
		}
	}

	private func finalizeScrollUpdates() {
		delegate?.scrollCoordinator(self, finalizeUpdate: state, newState: ignoredState)
		state = ignoredState
	}
	private func queueToFinalizeUpdates() {
		displayLink.start()
	}
}

extension ScrollCoordinator {
	func enqueueScroll(to newValue: ScrollPositionItem) {
		pendingScrollRequests.enqueue(newValue)
		queueToFinalizeUpdates()
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
				queueToFinalizeUpdates()
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		case .notAnimated:
			let transaction = Transaction.withoutAnimation { [weak self] in
				guard let self else { return }
				queueToFinalizeUpdates()
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		case .scroll:
			let transaction = Transaction.scrollView { [weak self] in
				guard let self else { return }
				queueToFinalizeUpdates()
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		}
	}

	private func scroll(to newValue: ScrollPositionItem) {
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
