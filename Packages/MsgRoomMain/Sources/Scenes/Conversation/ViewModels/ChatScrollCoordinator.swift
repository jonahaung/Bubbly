//
//  ChatScrollCoordinator.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 26/10/24.
//  Refactored by ChatGPT
//

import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

@MainActor
protocol ChatScrollCoordinatorDelegate: AnyObject {
	var canLoadOlderMessages: Bool { get }
	var canLoadNewerMessages: Bool { get }
	var newestMessage: Message? { get }
	var oldestMessage: Message? { get }
	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, didFinalizeUpdateAt position: ScrolledPosition)
	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, loadOlderStartingAt message: Message)
	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, loadNewerStartingAt message: Message)
	func reloadScrollView(for coordinator: ChatScrollCoordinator)
}

@MainActor
@Observable
final class ChatScrollCoordinator: ErrorPresenter, Equatable {

	var scrollTarget = ScrollPosition(edge: .bottom)
	var inputAccessoryFrame: CGRect?
	@ObservationIgnored private(set) var defaultAnimation: Animation?
	@ObservationIgnored private(set) var updateState = ScrollViewUpdatingState.initial
	@ObservationIgnored private(set) var isInputFirstResponder = false
	@ObservationIgnored private(set) var currentScrolledPosition = ScrolledPosition.atBottom
	@ObservationIgnored private(set) var scrollState = ScrollPhase.idle
	@ObservationIgnored let messageLayoutCache = MsgsScrollViewLayoutCache()
	@ObservationIgnored private var pendingScrollRequests = Deque<ScrollPositionItem>()
	@ObservationIgnored private let updateCoalescer = PassthroughSubject<String, Never>()
	@ObservationIgnored private(set) var scrollGeometry = VScrollGeometry.empty

	@ObservationIgnored weak var coordinatorDelegate: ChatScrollCoordinatorDelegate?
	@ObservationIgnored private let id: String
	@ObservationIgnored private let cancellables = CancelBag()

	init(id: String) {
		self.id = id
		updateCoalescer
			.debounce(for: 0.2, scheduler: RunLoop.main)
			.sink { [weak self] _ in
				guard let self else { return }
				Task { @MainActor in
					guard !isUserScrolling else {
						updateCoalescer.send(.init())
						return
					}
					finalizeScrollUpdates()
				}
			}
			.store(in: cancellables)
	}

	deinit {
		cancellables.cancel()
		log("Deinit")
	}

	func setDefaultAnimation(_ value: Animation?) {
		defaultAnimation = value
	}

	nonisolated static func == (lhs: ChatScrollCoordinator, rhs: ChatScrollCoordinator) -> Bool {
		lhs.id == rhs.id
	}
}

extension ChatScrollCoordinator {

	private var canLoadOlderMessages: Bool { coordinatorDelegate?.canLoadOlderMessages == true }
	private var canLoadNewerMessages: Bool { coordinatorDelegate?.canLoadNewerMessages == true }

	private func maybeLoadMoreMessages(_ newValue: VScrollGeometry) {
		guard updateState.isNotUpdating, !isInputFirstResponder else { return }
		let location = newValue.location
		switch location.edge {
		case .top:
			if location.fraction < 0.1, canLoadOlderMessages {
				guard let message = coordinatorDelegate?.oldestMessage else { return }
				setUpdateState(.insertingItems(.top))
				coordinatorDelegate?.scrollCoordinator(self, loadOlderStartingAt: message)
			}
		case .bottom:
			if location.fraction < 0.2, canLoadNewerMessages {
				guard let message = coordinatorDelegate?.newestMessage else { return }
				setUpdateState(.insertingItems(.bottom))
				coordinatorDelegate?.scrollCoordinator(self, loadNewerStartingAt: message)
			}
		}
	}
}

extension ChatScrollCoordinator {
	var isUserScrolling: Bool { scrollState.isScrolling }

	func didChangeScrollPhase(
		_: ScrollPhase,
		_ newValue: ScrollPhase,
		_ context: ScrollPhaseChangeContext
	) {

		scrollState = newValue
		if newValue == .idle {
			currentScrolledPosition = context.geometry.scrolledPosition
		}
		switch newValue {
		case .idle, .interacting:
			updateCoalescer.send(.init())
			if newValue == .interacting {
				if !pendingScrollRequests.isEmpty {
					pendingScrollRequests.removeAll()
				}
			} else {
				updateCoalescer.send(UUID().uuidString)
			}
		default:
			break
		}
	}

	func didChangeScrollGeometry(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry) {
		guard updateState.hasViewLoaded else {
			return
		}
		var vGeometry = newValue
		if updateState.isUpdating {
			guard oldValue.contentHeight != newValue.contentHeight else { return }
			switch updateState {
			case let .insertingItems(edge):
				switch edge {
				case .top:
					vGeometry.offsetY = newValue.adjustedOffsetY(from: oldValue)
					scrollTarget.scrollTo(y: vGeometry.offsetY)
				case .bottom:
					break
				}
				setUpdateState(.notLoading)
				updateCoalescer.send(.init())
			case let .removingItems(edge):
				switch edge {
				case .top:
					break
				case .bottom:
					vGeometry.offsetY = edge == .top ? newValue.visibleRect.minY : newValue.offsetY
					scrollTarget = .init(y: vGeometry.offsetY)
				}
				setUpdateState(.notLoading)
				updateCoalescer.send(.init())
			case .appendingItem:
				var transaction = Transaction.withAnimation(.interactiveSpring(duration: 0.3))
				transaction.addAnimationCompletion { [weak self] in
					self?.setUpdateState(.notLoading)
					self?.updateCoalescer.send(.init())
				}
				vGeometry.offsetY = newValue.bottomMostOffset
				withTransaction(transaction) { scrollTarget.scrollTo(y: vGeometry.offsetY) }
			case .resetting:
				vGeometry.offsetY = newValue.bottomMostOffset
				scrollTarget.scrollTo(y: vGeometry.offsetY - vGeometry.boundsHeight/2)
				enqueueScroll(to: .bottom())
				setUpdateState(.notLoading)
				updateCoalescer.send(.init())
			default:
				vGeometry.offsetY = newValue.offsetY
			}
		} else {
			guard oldValue.contentHeight == newValue.contentHeight else { return }
			if abs(oldValue.offsetY - newValue.offsetY) < 0.5 { return }
			if scrollState == .decelerating {
				maybeLoadMoreMessages(newValue)
			}
		}

		if scrollGeometry != vGeometry {
			scrollGeometry = vGeometry
		}
	}

	func didChangeInputAccessoryFrame(_ oldValue: CGRect, _ newValue: CGRect) {
		pendingScrollRequests.removeAll()
		if inputAccessoryFrame == nil {
			inputAccessoryFrame = newValue
		}
		guard updateState.hasViewLoaded else {
			coordinatorDelegate?.reloadScrollView(for: self)
			return
		}
		if oldValue.height == newValue.height {
			isInputFirstResponder = newValue.maxY < oldValue.maxY
		}
		if oldValue.width != newValue.width {
			coordinatorDelegate?.reloadScrollView(for: self)
			return
		}
		guard oldValue.height != newValue.height || oldValue.maxY != newValue.maxY else { return }

		if newValue.maxY < oldValue.maxY {
			if self.currentScrolledPosition == .atBottom {
				return
			}
			let targetY = scrollGeometry.offsetY + (
				oldValue.minY - newValue.minY
			) + scrollGeometry.topInset
			if scrollState.isScrolling {
				enqueueScroll(to: .offset(yPosition: targetY, animated: true, duration: 0.2))
			} else {
				scrollTarget.scrollTo(y: targetY)
			}
		}
	}
}

extension ChatScrollCoordinator {
	func enqueueScroll(to newValue: ScrollPositionItem) {
		let isEmpty = pendingScrollRequests.isEmpty
		pendingScrollRequests.enqueue(newValue)
		if isEmpty {
			updateCoalescer.send(newValue.hashValue.value)
		}

	}

	private func performPendingScrollIfNeeded() {
		guard let newValue = pendingScrollRequests.dequeue() else {
			return
		}
		performScroll(to: newValue)
	}

	func performScroll(to newValue: ScrollPositionItem) {
		if scrollState.isScrolling {
			enqueueScroll(to: newValue)
			return
		}
		switch newValue {
		case let .offset(value, animated, duration):
			withScrollTransaction(animated: animated, duration: duration) {
				scrollTarget.scrollTo(
					y: value
				)
			}
		case let .id(value, anchor, animated, duration):
			withScrollTransaction(animated: animated, duration: duration) {
				scrollTarget.scrollTo(
					id: value,
					anchor: anchor
				)
			}
		case let .layoutID(value, anchor, animated, duration):
			if let layout = messageLayoutCache.layout(for: value) {
				let rect = layout.frame
				let targetY: CGFloat =
				switch anchor {
				case .top:
					rect.minY - scrollGeometry.topInset
				case .bottom:
					scrollGeometry.targetOffsetY(for: rect)
				case .center:
					rect.midY - scrollGeometry.boundsHeight / 4
				default:
					scrollGeometry.targetOffsetY(for: rect)
				}
				withScrollTransaction(animated: animated, duration: duration) {
					scrollTarget.scrollTo(
						y: targetY
					)
				}
			}
		case let .bottom(animated, duration):
			withScrollTransaction(animated: animated, duration: duration) {
				scrollTarget.scrollTo(
					edge: .bottom
				)
			}
		}
	}

	private func withScrollTransaction(animated: Bool, duration: Double?, _ action: () -> Void) {
		var transaction = animated ? Transaction.withAnimation() : .withoutAnimation
		if let duration {
			transaction.animation = transaction.animation?.speed(duration)
		}
		if isUserScrolling {
			transaction.tracksVelocity = true
		}

		transaction.addAnimationCompletion(criteria: .removed) { [weak self] in
			guard let self else { return }
			if let duration {
				DispatchQueue.delay(duration) { [weak self] in
					guard let self else { return }
					performPendingScrollIfNeeded()
				}
			} else {
				DispatchQueue.delay { [weak self] in
					guard let self else { return }
					performPendingScrollIfNeeded()
				}
			}
		}
		withTransaction(transaction) { action() }
	}
}

extension ChatScrollCoordinator {
	func setUpdateState(_ newValue: ScrollViewUpdatingState) {
		guard updateState != .initial else { return }
		updateState = newValue
	}

	func markViewAsLoaded() {
		updateState = .notLoading
	}

	private func finalizeScrollUpdates() {
		coordinatorDelegate?.scrollCoordinator(self, didFinalizeUpdateAt: currentScrolledPosition)
		performPendingScrollIfNeeded()
	}
}
