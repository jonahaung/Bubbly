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
	func scrollCoordinator(_ coordinator: ChatScrollCoordinator,
	                       didFinalizeUpdateAt position: ScrolledPosition)
	func scrollCoordinator(_ coordinator: ChatScrollCoordinator,
	                       loadOlderStartingAt message: Message)
	func scrollCoordinator(_ coordinator: ChatScrollCoordinator,
	                       loadNewerStartingAt message: Message)
	func reloadScrollView(for coordinator: ChatScrollCoordinator)
}

@MainActor
@Observable
final class ChatScrollCoordinator: ErrorPresenter, Equatable {
	private var scrollTarget = ScrollPosition(edge: .bottom)
	var scrollPosition: Binding<ScrollPosition> {
		.init { [weak self] in
			guard let self else { return .init() }
			return scrollTarget
		} set: { [weak self] newValue in
			guard let self else { return }
			if newValue.isPositionedByUser {
				scrollTarget = newValue
			} else {
			}
		}
	}

	var inputAccessoryFrame: CGRect?
	@ObservationIgnored private(set) var defaultAnimation: Animation?
	@ObservationIgnored private(set) var updateState = ScrollViewUpdatingState.initial
	@ObservationIgnored private(set) var isInputFirstResponder = false
	@ObservationIgnored private(set) var scrolledPosition = ScrolledPosition.atBottom
	@ObservationIgnored private(set) var scrollPhase = ScrollPhase.idle
	@ObservationIgnored let messageLayoutCache = MsgsScrollViewLayoutCache()
	@ObservationIgnored private var pendingScrollRequests = Deque<ScrollPositionItem>()
	@ObservationIgnored private(set) var scrollGeometry = VScrollGeometry.empty
	@ObservationIgnored private(set) var scrollDirection = VerticalEdge.bottom
	@ObservationIgnored weak var coordinatorDelegate: ChatScrollCoordinatorDelegate?
	@ObservationIgnored private let id: String
	@ObservationIgnored private let displayLink = DisplayLink(0.3)

	init(id: String) {
		self.id = id
		displayLink.onTargetReached = { [weak self] _ in
			guard let self else {
				return
			}
			switch scrollPhase {
			case .idle:
				finalizeScrollUpdates()

			case .interacting:
				Haptics.play(.light, 0.8)

			default:
				break
			}
		}
	}

	deinit {
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
	private var canLoadOlderMessages: Bool {
		coordinatorDelegate?.canLoadOlderMessages == true
	}

	private var canLoadNewerMessages: Bool {
		coordinatorDelegate?.canLoadNewerMessages == true
	}
}

extension ChatScrollCoordinator {
	var isUserScrolling: Bool {
		scrollPhase.isScrolling
	}

	func didChangeScrollPhase(_ oldValue: ScrollPhase,
	                          _ newValue: ScrollPhase,
	                          _ context: ScrollPhaseChangeContext)
	{
		displayLink.stop()
		scrollPhase = newValue
		scrolledPosition = context.geometry.scrolledPosition
		let geometry = VScrollGeometry(context.geometry)
		scrollGeometry = geometry
		switch newValue {
		case .idle:
			displayLink.start()
		case .interacting:
			if !pendingScrollRequests.isEmpty {
				pendingScrollRequests.removeAll()
			}
		case .decelerating:
			if oldValue == .interacting, isInputFirstResponder, scrollDirection == .top {
				UIApplication.shared.endEditing()
			}
		default:
			break
		}
	}

	private func loadOlderMessagesIfNeeded() {
		guard let message = coordinatorDelegate?.oldestMessage else {
			return
		}

		setUpdateState(.insertingItems(.top))
		coordinatorDelegate?.scrollCoordinator(self, loadOlderStartingAt: message)
	}

	private func loadNewerMessagesIfNeeded() {
		guard let message = coordinatorDelegate?.newestMessage else {
			return
		}

		setUpdateState(.insertingItems(.bottom))
		coordinatorDelegate?.scrollCoordinator(self, loadNewerStartingAt: message)
	}

	func didChangeScrollGeometry(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry) {
		guard updateState.hasViewLoaded else {
			return
		}

		var vGeometry = newValue
		if updateState.isUpdating {
			guard oldValue.contentHeight != newValue.contentHeight else {
				switch updateState {
				case let .insertingItems(edge):
					switch edge {
					case .top:
						if newValue.offsetY < -newValue.topInset, canLoadOlderMessages {
							scrollTarget.scrollTo(y: 0)
						}
					case .bottom:
						break
					}
					setUpdateState(.notLoading)
					displayLink.start()
				default:
					break
				}
				return
			}

			let difference = newValue.contentHeight - oldValue.contentHeight
			switch updateState {
			case let .insertingItems(edge):
				switch edge {
				case .top:
					let offsetY = newValue.offsetY + difference + newValue.topInset
					scrollTarget.scrollTo(y: offsetY)
				case .bottom:
					let extraSpace = newValue.boundsHeight / 2
					let bottomMostOffset =
						newValue.contentHeight - newValue.boundsHeight - newValue.topInset
							- extraSpace
					if newValue.offsetY >= bottomMostOffset {
						scrollTarget.scrollTo(y: bottomMostOffset + newValue.topInset)
					}
				}
				setUpdateState(.notLoading)
				displayLink.start()
			case let .removingItems(edge):
				switch edge {
				case .top:
					setUpdateState(.notLoading)
				case .bottom:
					vGeometry.offsetY = newValue.offsetY + newValue.topInset
					scrollTarget.scrollTo(y: vGeometry.offsetY)
					setUpdateState(.insertingItems(.top))
				}
			case .appendingItem:
				var transaction = Transaction.withAnimation(.interactiveSpring(duration: 0.3))
				transaction.addAnimationCompletion { [weak self] in
					self?.setUpdateState(.notLoading)
					self?.displayLink.start()
				}
				vGeometry.offsetY = newValue.bottomMostOffset
				withTransaction(transaction) { scrollTarget.scrollTo(y: vGeometry.offsetY) }
			case .resetting:
				vGeometry.offsetY = newValue.bottomMostOffset
				scrollTarget.scrollTo(y: vGeometry.offsetY - vGeometry.boundsHeight / 2)
				enqueueScroll(to: .bottom())
				setUpdateState(.notLoading)
				displayLink.start()
			default:
				vGeometry.offsetY = newValue.offsetY + newValue.topInset
			}
			scrollGeometry = vGeometry
		} else {
			guard oldValue.contentHeight == newValue.contentHeight else {
				return
			}
			if updateState.isNotUpdating {
				let direction: VerticalEdge = newValue.offsetY > oldValue.offsetY ? .bottom : .top
				switch direction {
				case .top:
					if newValue.offsetY < -newValue.topInset, canLoadOlderMessages {

						scrollTarget.scrollTo(y: 0)
						loadOlderMessagesIfNeeded()
					}
				case .bottom:
					let extraSpace = newValue.boundsHeight / 2
					let bottomMostOffset =
						newValue.contentHeight - newValue.boundsHeight - newValue.topInset
							- extraSpace
					if newValue.offsetY >= bottomMostOffset, canLoadNewerMessages {
						loadNewerMessagesIfNeeded()
					}
				}
				scrollDirection = direction
			}
		}
	}

	func didChangeInputAccessoryFrame(_ oldValue: CGRect, _ newValue: CGRect) {
		pendingScrollRequests.removeAll()
		if inputAccessoryFrame == nil {
			inputAccessoryFrame = newValue
		}
		guard updateState.hasViewLoaded else { return }

		if oldValue.height == newValue.height {
			isInputFirstResponder = newValue.maxY < oldValue.maxY
		}
		if oldValue.width != newValue.width {
			inputAccessoryFrame = newValue
			coordinatorDelegate?.reloadScrollView(for: self)
			return
		}
		guard oldValue.height != newValue.height || oldValue.maxY != newValue.maxY else {
			return
		}

		if newValue.maxY < oldValue.maxY {
			if scrolledPosition == .atBottom {
				return
			}
			let targetY =
				scrollGeometry.offsetY + (oldValue.minY - newValue.minY) + scrollGeometry.topInset
			if scrollPhase.isScrolling {
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
			displayLink.start()
		}
	}

	private func performPendingScrollIfNeeded() {
		guard let newValue = pendingScrollRequests.dequeue() else {
			return
		}

		performScroll(to: newValue)
	}

	func performScroll(to newValue: ScrollPositionItem) {
		if scrollPhase.isScrolling {
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
			withScrollTransaction(animated: animated, duration: duration) {
				scrollTarget.scrollTo(
					id: value,
					anchor: anchor
				)
			}
//			if let layout = messageLayoutCache.layout(for: value) {
//				let rect = layout.frame
//				let targetY: CGFloat =
//					switch anchor {
//					case .top:
//						rect.minY - scrollGeometry.topInset
//					case .bottom:
//						scrollGeometry
//							.targetOffsetY(for: rect) + ChatLayoutConstants.bottomBarHeight
//					case .center:
//						rect.midY - scrollGeometry.boundsHeight / 4
//					default:
//						scrollGeometry.targetOffsetY(for: rect)
//					}
//				withScrollTransaction(animated: animated, duration: duration) {
//					scrollTarget.scrollTo(
//						y: targetY
//					)
//				}
//			}
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
			guard let self else {
				return
			}

			if let duration {
				DispatchQueue.delay(duration) { [weak self] in
					guard let self else {
						return
					}

					performPendingScrollIfNeeded()
				}
			} else {
				DispatchQueue.delay { [weak self] in
					guard let self else {
						return
					}

					performPendingScrollIfNeeded()
				}
			}
		}
		withTransaction(transaction) { action() }
	}
}

extension ChatScrollCoordinator {
	func setUpdateState(_ newValue: ScrollViewUpdatingState) {
		guard updateState != .initial else {
			return
		}

		updateState = newValue
	}

	func markViewAsLoaded() {
		updateState = .notLoading
	}

	private func finalizeScrollUpdates() {
		coordinatorDelegate?.scrollCoordinator(self, didFinalizeUpdateAt: scrolledPosition)
		performPendingScrollIfNeeded()
	}
}

