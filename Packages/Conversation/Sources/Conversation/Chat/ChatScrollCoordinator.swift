import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

@MainActor
protocol ChatScrollCoordinatorDelegate: Sendable, AnyObject {
	func scrollCoordinator(
		_ coordinator: ChatScrollCoordinator,
		shouldPaginateAt edge: VerticalEdge
	) -> Bool
	func scrollCoordinator(
		_ coordinator: ChatScrollCoordinator,
		paginateAt edge: VerticalEdge
	)
	func scrollCoordinator(
		_ coordinator: ChatScrollCoordinator,
		removeAt edge: VerticalEdge
	)
	func scrollCoordinator(
		_ coordinator: ChatScrollCoordinator,
		didFinalizeUpdateAt position: ScrolledPosition
	)
}

@MainActor
@Observable
final class ChatScrollCoordinator: ErrorPresenter {
	let throttler = Throttler(interval: .seconds(0.5))
	private var scrollTarget = ScrollPosition(edge: .bottom)
	var scrollPosition: Binding<ScrollPosition> {
		.init(
			get: { [weak self] in
				guard let self else { return .init() }
				return self.scrollTarget
			})
		{ [weak self] newValue in
			guard let self else { return }
			if newValue.isPositionedByUser {
			} else {
				self.scrollTarget = .init()
			}
		}
	}
	var inputAccessoryFrame: CGRect?
	@ObservationIgnored private var pendingScrollRequests = Deque<ScrollPositionItem>()
	@ObservationIgnored weak var delegate: ChatScrollCoordinatorDelegate?
	@ObservationIgnored private let reducer = ScrollReducer()
	@ObservationIgnored private let displayLink = DisplayLink(0.5)
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
	func loadOlderMessagesIfNeeded() {
		delegate?.scrollCoordinator(self, paginateAt: .top)
	}

	private func loadNewerMessagesIfNeeded() {
		delegate?.scrollCoordinator(self, paginateAt: .bottom)
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
		case .onVisibilityChange(let visibility):
			switch visibility {
			case .automatic:
				break
			case .visible:
				state.updateState.setHasViewLoaded()
			case .hidden:
				break
			}
		case .onBottomBarFrameChage(let oldValue, let newValue):

			guard newValue.origin.x >= 0 else { return }
			if inputAccessoryFrame == nil && newValue.maxX > 0 {
				inputAccessoryFrame = newValue
				return
			}
			guard state.updateState.hasViewLoaded else { return }
			if newValue.maxX != oldValue.maxX {
				scrollTarget = .init()
				inputAccessoryFrame = newValue
				return
			}
			if newValue.height == oldValue.height && newValue.maxY != oldValue.maxY {
				state.isFirstResponder = newValue.maxY < oldValue.maxY
			}
			guard state.updateState.isNotUpdating else { return }
			guard newValue.maxY < oldValue.maxY else { return }
			guard state.geometry.scrolledPosition != .atBottom else { return }
			let targetY = state.geometry.offsetY + oldValue.maxY - newValue.maxY
			if state.phase.isScrolling {
				enqueueScroll(to: .y(targetY, animation: .interactiveSpring(duration: 0.2)))
			} else {
				scrollTarget.scrollTo(y: targetY)
			}
		case .onScrollGeometryChange(let oldValue, let newValue):
			state.geometry = newValue
			state.direction = newValue.offsetY < oldValue.offsetY ? .top : .bottom
		case .onScrollPhaseChange(let oldValue, let newValue, let context):
			displayLink.stop()
			state.phase = newValue
		case .onScrollTargetVisibilityChange(let newValue):
			guard state.updateState.isNotUpdating else { return }
			state.visibleIDs = newValue
		}
	}

	private func perform(_ effect: ScrollEffect) {
		switch effect {
		case .scroll(let item):
			performScroll(to: item)
		case let .begingUpdate(intent):
			switch intent {
			case .insertItems(let edge):
				state.updateState.update(to: .insertingItems(edge))
				switch edge {
				case .top:
					loadOlderMessagesIfNeeded()
				case .bottom:
					loadNewerMessagesIfNeeded()
				}
			case .removeItems(let edge):
				state.updateState.update(to: .removingItems(edge))
				delegate?.scrollCoordinator(self, removeAt: edge)
			}
		case let .endUpdate(intent, item):
			if let item {
				performScroll(to: item)
			}
			switch intent {
			case .insertItems(let edge):
				state.updateState.update(to: .notUpdating)
			case .removeItems(let edge):
				switch edge {
				case .top:
					state.updateState.update(to: .notUpdating)
				case .bottom:
					state.updateState.update(to: .insertingItems(.top))
					loadOlderMessagesIfNeeded()
				}
			}
		case .finalizeScrollViewUpdates:
			displayLink.start(0.5)
		case .removePendingUpdates:
			pendingScrollRequests.removeAll()
		case .noAction:
			break
		}
	}
}

extension ChatScrollCoordinator {
	func enqueueScroll(to newValue: ScrollPositionItem) {
		let isEmpty = pendingScrollRequests.isEmpty
		pendingScrollRequests.enqueue(newValue)
		if isEmpty {
			performPendingScrollIfNeeded()
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
				guard state.updateState.isNotUpdating else {
					return
				}
				displayLink.start(0.5)
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		} else {
			let transaction = Transaction.scrollView(
				preservePosition: false
			) { [weak self] in
				guard let self else { return }
				guard state.updateState.isNotUpdating else {
					return
				}
				displayLink.start(0.5)
			}
			withTransaction(transaction) {
				scroll(to: newValue)
			}
		}
	}

	private func scroll(to newValue: ScrollPositionItem) {
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
			let geometry = state.geometry
			let offsetY = geometry.bottomMostOffset
			let y = offsetY - geometry.boundsHeight / 2
			if y > geometry.offsetY {
				scrollTarget.scrollTo(y: y)
			}
			enqueueScroll(to: .edge(.bottom, animation: .interpolatingSpring))
		case .snapToY(let y):
			let geometry = state.geometry
			let halfViewport = geometry.boundsHeight * 0.5
			let currentOffset = geometry.offsetY

			let direction: CGFloat = y > currentOffset ? -1 : 1
			let adjustedY = y + (direction * halfViewport)

			let clampedY = max(0, min(adjustedY, geometry.bottomMostOffset))

			scrollTarget.scrollTo(y: clampedY)
			enqueueScroll(to: .y(clampedY, animation: .smooth))
		}
	}

	private func finalizeScrollUpdates() {
		if !pendingScrollRequests.isEmpty {
			performPendingScrollIfNeeded()
			return
		}
		delegate?.scrollCoordinator(self, didFinalizeUpdateAt: state.geometry.scrolledPosition)
	}
}


//import Database
//import Services
//import SwiftUI
//import XUI
//
//struct VelocityTracker {
//
//
//	private(set) var velocity: CGFloat = 0
//
//	private var lastValue: CGFloat = 0
//	private var lastTimestamp: CFTimeInterval = 0
//
//	mutating func update(value: CGFloat) {
//		let now = CACurrentMediaTime()
//
//		defer {
//			lastValue = value
//			lastTimestamp = now
//		}
//
//		guard lastTimestamp != 0 else { return }
//
//		let deltaValue = value - lastValue
//		let deltaTime = now - lastTimestamp
//		guard deltaTime > 0 else { return }
//
//		let rawVelocity = deltaValue / CGFloat(deltaTime)
//		velocity = velocity * 0.85 + rawVelocity * 0.15
//	}
//}
//
//@MainActor
//protocol ChatScrollCoordinatorDelegate: AnyObject {
//	var canLoadOlderMessages: Bool { get }
//	var canLoadNewerMessages: Bool { get }
//	var newestMessage: Message? { get }
//	var oldestMessage: Message? { get }
//	func scrollCoordinator(_ coordinator: ChatScrollCoordinator,
//						   didFinalizeUpdateAt position: ScrolledPosition)
//	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, removeAt edge: VerticalEdge)
//	func scrollCoordinator(_ coordinator: ChatScrollCoordinator,
//						   insertAt edge: VerticalEdge,
//						   msg: Message)
//}
//
//@MainActor
//@Observable
//final class ChatScrollCoordinator: ErrorPresenter {
//	var scrollTarget = ScrollPosition(edge: .bottom)
//	var inputAccessoryFrame: CGRect?
//	var scrollPosition: Binding<ScrollPosition> {
//		.init(get: { self.scrollTarget }) { _ in
//			//			self.scrollTarget = .init()
//		}
//	}
//	@ObservationIgnored private var pendingScrollRequests = Deque<ScrollPositionItem>()
//	@ObservationIgnored private let displayLink = DisplayLink(0.7)
//	@ObservationIgnored var state = ScrollState()
//	@ObservationIgnored private let reducer = ScrollReducer()
//	@ObservationIgnored weak var delegate: ChatScrollCoordinatorDelegate?
//	@ObservationIgnored var visibleIDs = [String]()
//	@ObservationIgnored private var tracker = VelocityTracker()
//	init() {
//		displayLink.onTargetReached = { [weak self] _ in
//			guard let self else { return }
//			finalizeScrollUpdates()
//		}
//	}
//
//	private var canLoadOlderMessages: Bool {
//		delegate?.canLoadOlderMessages == true && state.updateState.type == .none
//	}
//
//	private var canLoadNewerMessages: Bool {
//		delegate?.canLoadNewerMessages == true && state.updateState.type == .none
//	}
//
//	func send(_ intent: ScrollViewIntent) {
//		if prepare(intent, state: &state) {
//			let effect = reducer.reduce(
//				state: &state,
//				intent: intent,
//				canLoadOlder: canLoadOlderMessages,
//				canLoadNewer: canLoadNewerMessages
//			)
//			perform(effect)
//		}
//	}
//
//	func canFinalizeInsert(at edge: VerticalEdge) -> Bool {
//		switch edge {
//		case .top:
//			state.updateState.type == .insert(.top)
//		case .bottom: false
//		}
//	}
//}
//
//private extension ChatScrollCoordinator {
//	func prepare(_ intent: ScrollViewIntent, state: inout ScrollState) -> Bool {
//		switch intent {
//		case .onViewAppear:
//			return true
//		case let .onScrollGeometryChange(oldValue: oldValue, newValue: newValue):
//			tracker.update(value: newValue.offsetY)
//			let normalized = (min(abs(tracker.velocity) / 2000, 1) * 100).int
//			state.velocity = normalized
//			return oldValue != newValue
//		case .onScrollPhaseChange:
//			displayLink.stop()
//			return true
//		case let .onInputBarGeometryChange(oldValue, newValue):
//			guard newValue.origin.x >= 0 else { return false }
//			if inputAccessoryFrame?.maxX != newValue.maxX {
//				inputAccessoryFrame = newValue
//				return false
//			}
//			guard state.updateState.hasViewLoaded else {
//				return false
//			}
//			pendingScrollRequests.removeAll()
//			if oldValue.height == newValue.height {
//				state.isFirstResponder = newValue.maxY < oldValue.maxY
//			}
//			guard oldValue.maxY > newValue.maxY else {
//				return false
//			}
//			guard state.scrolledPosition != .atBottom else {
//				return false
//			}
//			let targetY =
//			state.geometry.offsetY
//			+ (oldValue.minY - newValue.minY)
//			+ state.geometry.topInset
//			if state.phase.isScrolling {
//				enqueueScroll(to: .y(targetY, animation: .easeInOut))
//			} else {
//				scrollTarget = .init(y: targetY)
//			}
//			return false
//		case let .onScrollTargetVisibilityChange(ids):
//			visibleIDs = ids
//
//			return false
//		}
//	}
//
//	func prepare2(_ intent: ScrollViewIntent, state: inout ScrollState) -> Bool {
//		switch intent {
//		case .onViewAppear:
//			return true
//		case let .onScrollGeometryChange(oldValue: oldValue, newValue: newValue):
//			tracker.update(value: newValue.offsetY)
//			let normalized = (min(abs(tracker.velocity) / 2000, 1) * 100).int
//			state.velocity = normalized
//			return oldValue != newValue
//		case .onScrollPhaseChange:
//			displayLink.stop()
//			return true
//		case let .onInputBarGeometryChange(oldValue, newValue):
//			guard newValue.origin.x >= 0 else { return false }
//			if inputAccessoryFrame?.maxX != newValue.maxX {
//				inputAccessoryFrame = newValue
//				return false
//			}
//			guard state.updateState.hasViewLoaded else {
//				return false
//			}
//			pendingScrollRequests.removeAll()
//			if oldValue.height == newValue.height {
//				state.isFirstResponder = newValue.maxY < oldValue.maxY
//			}
//			guard oldValue.maxY > newValue.maxY else {
//				return false
//			}
//			guard state.scrolledPosition != .atBottom else {
//				return false
//			}
//			let targetY =
//			state.geometry.offsetY
//			+ (oldValue.minY - newValue.minY)
//			+ state.geometry.topInset
//			if state.phase.isScrolling {
//				enqueueScroll(to: .y(targetY, animation: .easeInOut))
//			} else {
//				scrollTarget = .init(y: targetY)
//			}
//			return false
//		case let .onScrollTargetVisibilityChange(ids):
//			visibleIDs = ids
//
//			return false
//		}
//	}
//
//	func perform(_ effect: ReduceEffect) {
//		switch effect {
//		case let .adjustScrollPosition(newValue):
//			performScroll(to: newValue)
//		case .finalizeScrollViewUpdate:
//			displayLink.start(0.5)
//		case let .loadMoreItems(edge):
//			pendingScrollRequests.removeAll()
//			switch edge {
//			case .top:
//				loadOlderMessagesIfNeeded()
//			case .bottom:
//				loadNewerMessagesIfNeeded()
//			}
//		case .noAction:
//			break
//		case .removePendingScrolls:
//			pendingScrollRequests.removeAll()
//		case let .removeSomeItems(edge):
//			delegate?.scrollCoordinator(self, removeAt: edge)
//			performScroll(to: .init(.y(state.geometry.boundsHeight/2)))
//		case .resignFirstResponder:
//			UIApplication.shared.endEditing()
//		}
//	}
//}
//
//extension ChatScrollCoordinator {
//	func loadOlderMessagesIfNeeded() {
//		guard let message = delegate?.oldestMessage else { return }
//		delegate?.scrollCoordinator(self, insertAt: .top, msg: message)
//	}
//
//	func loadNewerMessagesIfNeeded() {
//		guard let message = delegate?.newestMessage else { return }
//		delegate?.scrollCoordinator(self, insertAt: .bottom, msg: message)
//	}
//}
//
//extension ChatScrollCoordinator {
//	func enqueueScroll(to newValue: ScrollPositionItem) {
//		let isEmpty = pendingScrollRequests.isEmpty
//		pendingScrollRequests.enqueue(newValue)
//		if isEmpty {
//			displayLink.start(0.2)
//		}
//	}
//
//	private func performPendingScrollIfNeeded() {
//		guard let newValue = pendingScrollRequests.dequeue() else {
//			return
//		}
//		performScroll(to: newValue)
//	}
//
//	func performScroll(to newValue: ScrollPositionItem) {
//		if !state.updateState.isUpdating, state.phase.isScrolling, newValue.animation != nil {
//			enqueueScroll(to: newValue)
//			return
//		}
//		if let animation = newValue.animation {
//			withTransaction(.withAnimation(animation, completion: { [weak self] in
//				guard let self else { return }
//				displayLink.start()
//			})) {
//				scroll(to: newValue)
//			}
//		} else {
//			withTransaction(.scrollView(anchor: state.direction == .top ? .top : .bottom)) {
//				scroll(to: newValue)
//			}
//		}
//	}
//
//	func scroll(to newValue: ScrollPositionItem) {
//		switch newValue.position {
//		case let .edge(edge):
//			if scrollTarget.edge == edge {
//				performScroll(to: .snapToY(state.geometry.bottomMostOffset))
//			} else {
//				scrollTarget = .init(edge: edge)
//			}
//		case let .id(id):
//			scrollTarget = .init(id: id, anchor: .top)
//		case let .layoutID(layoutID):
//			scrollTarget.scrollTo(id: layoutID)
//		case let .y(offsetY):
//			scrollTarget = .init(y: offsetY)
//		case .snapToBottom:
//			let geometry = state.geometry
//			let bottomMost = geometry.bottomMostOffset
//			let y = bottomMost - geometry.boundsHeight / 2
//			if y > geometry.offsetY {
//				scrollTarget = .init(y: y)
//			}
//			enqueueScroll(to: .y(bottomMost, animation: .interpolatingSpring))
//		case let .snapToY(y):
//			let geometry = state.geometry
//			let halfViewport = geometry.boundsHeight * 0.5
//			let currentOffset = geometry.offsetY
//
//			let direction: CGFloat = y > currentOffset ? -1 : 1
//			let adjustedY = y + (direction * halfViewport)
//
//			let clampedY = max(0, min(adjustedY, geometry.bottomMostOffset))
//
//			scrollTarget.scrollTo(y: clampedY)
//			enqueueScroll(to: .y(clampedY, animation: .interpolatingSpring))
//		}
//	}
//
//	private func finalizeScrollUpdates() {
//
//		performPendingScrollIfNeeded()
//		delegate?.scrollCoordinator(self, didFinalizeUpdateAt: state.scrolledPosition)
//	}
//}
