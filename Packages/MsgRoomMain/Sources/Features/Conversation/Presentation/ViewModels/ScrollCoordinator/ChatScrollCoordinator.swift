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
	var scrollTarget = ScrollPosition(edge: .bottom)
	var inputAccessoryFrame: CGRect?

	@ObservationIgnored private(set) var defaultAnimation: Animation?
	@ObservationIgnored private var pendingScrollRequests = Deque<ScrollPositionItem>()
	@ObservationIgnored private let displayLink = DisplayLink(0.3)
	@ObservationIgnored private var isInputFirstResponder = false
	@ObservationIgnored weak var delegate: ChatScrollCoordinatorDelegate?

	var state = ScrollState(
		updateState: .initial,
		scrollGeometry: .empty,
		scrollDirection: .bottom,
		scrolledPosition: .atBottom,
		phase: .idle
	)

	private var reducer = ScrollReducer()

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

	func setDefaultAnimation(_ value: Animation?) {
		defaultAnimation = value
	}
}

extension ChatScrollCoordinator {
	private var canLoadOlderMessages: Bool {
		delegate?.canLoadOlderMessages == true
	}

	private var canLoadNewerMessages: Bool {
		delegate?.canLoadNewerMessages == true
	}
}

extension ChatScrollCoordinator {
	func didChangeScrollPhase(_ oldValue: ScrollPhase,
	                          _ newValue: ScrollPhase,
	                          _ context: ScrollPhaseChangeContext)
	{
		let effect = reducer.reduce(
			state: &state,
			action: .phaseChanged(
				old: oldValue,
				new: newValue,
				context: context
			),
			canLoadOlder: canLoadOlderMessages,
			canLoadNewer: canLoadNewerMessages
		)

		perform(effect)
	}

	func didChangeScrollGeometry(_ oldValue: VScrollGeometry,
	                             _ newValue: VScrollGeometry)
	{
		let effect = reducer.reduce(
			state: &state,
			action: .geometryChanged(old: oldValue, new: newValue),
			canLoadOlder: canLoadOlderMessages,
			canLoadNewer: canLoadNewerMessages
		)
		perform(effect)
	}

	func markViewAsLoaded() {
		let effect = reducer.reduce(
			state: &state,
			action: .viewLoaded,
			canLoadOlder: canLoadOlderMessages,
			canLoadNewer: canLoadNewerMessages
		)

		perform(effect)
	}

	private func loadOlderMessagesIfNeeded() {
		guard let message = delegate?.oldestMessage else { return }
		delegate?.scrollCoordinator(self, loadOlderStartingAt: message)
	}

	private func loadNewerMessagesIfNeeded() {
		guard let message = delegate?.newestMessage else { return }
		delegate?.scrollCoordinator(self, loadNewerStartingAt: message)
	}

	private func perform(_ effect: ScrollEffect) {
		switch effect {
		case let .scrollToOffset(y, animated, duration):
			withScrollTransaction(animated: animated, duration: duration) {
				scrollTarget.scrollTo(y: y)
			}

		case let .scrollToBottom(animated, duration):
			withScrollTransaction(animated: animated, duration: duration) {
				scrollTarget.scrollTo(edge: .bottom)
			}

		case .loadOlder:
			loadOlderMessagesIfNeeded()

		case .loadNewer:
			loadNewerMessagesIfNeeded()

		case .finalizeUpdate:
			finalizeScrollUpdates()

		case .none:
			guard pendingScrollRequests.isEmpty else { return }
			switch state.phase {
			case .idle:
				displayLink.start()
			case .interacting:
				if isInputFirstResponder {
					UIApplication.shared.endEditing()
				}
			default:
				break
			}
		}
	}

	func didChangeInputAccessoryFrame(_ oldValue: CGRect, _ newValue: CGRect) {
		let effect = reducer.reduce(
			state: &state,
			action: .inputAccessoryChanged(old: oldValue, new: newValue),
			canLoadOlder: canLoadOlderMessages,
			canLoadNewer: canLoadNewerMessages
		)
		perform(effect)
		pendingScrollRequests.removeAll()
		if inputAccessoryFrame == nil {
			inputAccessoryFrame = newValue
			delegate?.reloadScrollView(for: self)
			return
		}
		guard state.updateState.hasViewLoaded else { return }

		if oldValue.height == newValue.height {
			isInputFirstResponder = newValue.maxY < oldValue.maxY
		}
		if oldValue.width != newValue.width {
			inputAccessoryFrame = newValue
			delegate?.reloadScrollView(for: self)
			return
		}
		guard oldValue.height != newValue.height || oldValue.maxY != newValue.maxY else {
			return
		}
		if newValue.maxY < oldValue.maxY {
			if state.scrolledPosition == .atBottom {
				return
			}
			let targetY =
				state.scrollGeometry.offsetY + (oldValue.minY - newValue.minY)
					+ state.scrollGeometry.topInset
			if state.phase.isScrolling {
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
			transaction.animation = .easeInOut(duration: duration)
		}

		transaction.addAnimationCompletion(criteria: .removed) { [weak self] in
			guard let self else {
				return
			}

			if let duration {
				displayLink.start(duration)
			} else {
				displayLink.start()
			}
		}
		withTransaction(transaction) { action() }
	}

	private func finalizeScrollUpdates() {
		delegate?.scrollCoordinator(self, didFinalizeUpdateAt: state.scrolledPosition)
		performPendingScrollIfNeeded()
	}
}
