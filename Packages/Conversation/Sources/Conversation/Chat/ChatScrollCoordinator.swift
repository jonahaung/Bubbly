import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

/*
 A unidirectional flow (Action → Reducer → Effect)
 •	Deterministic scroll state
 •	Deferred scroll batching
 •	Keyboard-aware offset correction
 •	Phase-aware haptics + dismiss
 •	Animation completion scheduling
 */

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
final class ChatScrollCoordinator: ErrorPresenter {
	private var scrollTarget = ScrollPosition(edge: .bottom)
	var scrollPosition: Binding<ScrollPosition> { 
		.init(get: { self.scrollTarget }) { newValue in
			if !newValue.isPositionedByUser {
				self.scrollTarget = .init()
			}
		}
	}
	var inputAccessoryFrame: CGRect?
	@ObservationIgnored private var pendingScrollRequests = Deque<ScrollPositionItem>()
	@ObservationIgnored weak var delegate: ChatScrollCoordinatorDelegate?
	@ObservationIgnored private let reducer = ScrollReducer()
	@ObservationIgnored private let displayLink = DisplayLink(0.3)
	@ObservationIgnored var state = ScrollState()

	init() {
		displayLink.onTargetReached = { [weak self] _ in
			guard let self else { return }

			switch state.phase {
			case .idle:
				finalizeScrollUpdates()
			case .interacting:
				Haptics.play(.light, 0.8)
			default:
				break
			}
		}
	}
}

extension ChatScrollCoordinator {
	private var canLoadOlderMessages: Bool {
		delegate?.canLoadOlderMessages == true && state.updateState.isNotUpdating
	}

	private var canLoadNewerMessages: Bool {
		delegate?.canLoadNewerMessages == true && state.updateState.isNotUpdating
	}
	private func loadOlderMessagesIfNeeded() {
		guard let message = delegate?.oldestMessage else { return }
		delegate?.scrollCoordinator(self, loadOlderStartingAt: message)
	}

	private func loadNewerMessagesIfNeeded() {
		guard let message = delegate?.newestMessage else { return }
		delegate?.scrollCoordinator(self, loadNewerStartingAt: message)
	}
}

extension ChatScrollCoordinator {

	func send(_ intent: ScrollViewIntent) {
		prepare(intent)
		let effect = reducer.reduce(
			state: &state,
			intent: intent,
			canLoadOlder: canLoadOlderMessages,
			canLoadNewer: canLoadNewerMessages
		)

		perform(effect)
	}

	private func prepare(_ intent: ScrollViewIntent) {
		switch intent {
		case let .onVisibilityChange(visibility):
			switch visibility {
			case .automatic:
				break
			case .visible:
				state.updateState.setHasViewLoaded()
			case .hidden:
				break
			}
		case let .onBottomBarFrameChage(oldValue, newValue):
			if inputAccessoryFrame == nil && newValue.maxX > 0 {
				inputAccessoryFrame = newValue
				return
			}
			guard state.updateState.hasViewLoaded else { return }
			if newValue.maxX != oldValue.maxX {
				inputAccessoryFrame = newValue
				return
			}

			if newValue.height == oldValue.height && newValue.maxY != oldValue.maxY {
				state.isFirstResponder = newValue.maxY < oldValue.maxY
			}

			guard newValue.maxY < oldValue.maxY else { return }
			guard state.position != .atBottom else { return }
			let targetY = state.geometry.offsetY + oldValue.maxY - newValue.maxY
			if state.phase.isScrolling {
				enqueueScroll(to: .y(targetY, animation: .interactiveSpring(duration: 0.2)))
			} else {
				scrollTarget.scrollTo(y: targetY)
			}
		case let .onScrollGeometryChange(oldValue, newValue):
			state.geometry = newValue
			state.direction = newValue.offsetY < oldValue.offsetY ? .top : .bottom
		case let .onScrollPhaseChange(oldValue, newValue, context):
			let geometry = VScrollGeometry(context.geometry)
			state.position = geometry.scrolledPosition
			state.phase = newValue
		case let .onScrollTargetVisibilityChange(newValue):
			state.visibleIDs = newValue
		}
	}

	private func perform(_ effect: ScrollEffect) {
		switch effect {
		case .scroll(let item):
			performScroll(to: item)
		case .insertItems(let edge):
			switch edge {
			case .top:
				loadOlderMessagesIfNeeded()
			case .bottom:
				loadNewerMessagesIfNeeded()
			}
		case .removeItems(let edge):
			switch edge {
			case .top:
				break
			case .bottom:
				break
			}
		case .finalizeScrollViewUpdates:
			displayLink.start()
		case .removePendingUpdates:
			pendingScrollRequests.removeAll()
		case .noAction:
			break
		}
	}

//	func didChangeInputAccessoryFrame(_ oldValue: CGRect, _ newValue: CGRect) {
//		let effect = reducer.reduce(
//			state: &state,
//			action: .inputAccessoryChanged(old: oldValue, new: newValue),
//			canLoadOlder: canLoadOlderMessages,
//			canLoadNewer: canLoadNewerMessages
//		)
//		perform(effect)
//		pendingScrollRequests.removeAll()
//		if oldValue.maxX != newValue.maxX {
//			inputAccessoryFrame = newValue
//		}
//
//		guard state.updateState.hasViewLoaded else {
//			scrollTarget = .init(y: state.geometry.bottomMostOffset)
//			return
//		}
//		guard state.updateState.hasViewLoaded else { return }
//
//		if oldValue.height == newValue.height {
//			state.isFirstResponder = newValue.maxY < oldValue.maxY
//		}
//
//		guard oldValue.height != newValue.height || oldValue.maxY != newValue.maxY else {
//			return
//		}
//			if newValue.maxY < oldValue.maxY {
//				if state.position == .atBottom {
//					enqueueScroll(to: .edge(.bottom, animation: .interactiveSpring(duration: 0.25)))
//					return
//				}
//				let targetY =
//					state.geometry.offsetY + (oldValue.minY - newValue.minY)
//						+ state.geometry.topInset
//				if state.phase.isScrolling {
//					enqueueScroll(to: .y(targetY, animation: .interactiveSpring(duration: 0.2)))
//				} else {
//					scrollTarget.scrollTo(y: targetY)
//				}
//			}
//	}
}

extension ChatScrollCoordinator {
	func enqueueScroll(to newValue: ScrollPositionItem) {
		let isEmpty = pendingScrollRequests.isEmpty
		pendingScrollRequests.enqueue(newValue)
		if isEmpty {
			displayLink.start(0.1)
		}
	}

	private func performPendingScrollIfNeeded() {
		guard let newValue = pendingScrollRequests.dequeue() else {
			return
		}

		performScroll(to: newValue)
	}

	func performScroll(to newValue: ScrollPositionItem) {
		if let animation = newValue.animation {
			let transaction = Transaction.withAnimation(animation) { [weak self] in
				guard let self else { return }
				displayLink.start()
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		} else {
			let transaction = Transaction.scrollView(preservePosition: false) { [weak self] in
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
			scrollTarget.scrollTo(y: value)
		case .id(let value):
			scrollTarget.scrollTo(id: value)
		case .layoutID(let value):
			scrollTarget.scrollTo(id: value)
		case .edge(let edge):
			scrollTarget.scrollTo(edge: edge)
		case .snapToBottom:
			let offsetY = state.geometry.bottomMostOffset
			let y = offsetY - state.geometry.boundsHeight/2
			scrollTarget.scrollTo(y: y)
			enqueueScroll(to: .y(offsetY, animation: .smooth))
		case let .snapToY(y):
			let geometry = state.geometry
			scrollTarget.scrollTo(y: y-geometry.boundsHeight/2)
			enqueueScroll(to: .y(y, animation: .smooth))
		}
	}

	private func finalizeScrollUpdates() {
		delegate?.scrollCoordinator(self, didFinalizeUpdateAt: state.position)
		performPendingScrollIfNeeded()
		if state.updateState.isUpdating {
			state.updateState.endUpdating()
		}
	}
}
