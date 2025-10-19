//
//  ChatScrollManager.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 26/10/24.
//  Refactored by ChatGPT
//

import Core
import Database
import ImageLoader
import SwiftUI
import XUI
import Combine
import Services

@MainActor
protocol ChatScrollManagerDelegate: AnyObject {
	var canLoadPrevious: Bool { get }
	var canLoadMore: Bool { get }
	var lastMsg: MsgSnapshot? { get }
	var firstMsg: MsgSnapshot? { get }
	func scrollManager(_ manager: ChatScrollManager, finalizeScrollViewUpdate position: ScrolledPosition)
	func scrollManager(_ manager: ChatScrollManager, loadPrevious msg: MsgSnapshot)
	func scrollManager(_ manager: ChatScrollManager, loadMore msg: MsgSnapshot)
	func scrollManager(_ manager: ChatScrollManager, didUpdateBoundsWidth newValue: CGFloat)
}

@MainActor
@Observable
final class ChatScrollManager: ErrorPresenter {

	private(set) var scrollPosition = ScrollPosition.userDefined
	private(set) var scrolledPosition = ScrolledPosition.atBottom
	private(set) var bottomBarFrame = CGRect.zero
	private(set) var updatingState = ScrollViewUpdatingState.initial
	private(set) var isScrollingStopped = false
	@ObservationIgnored private(set) var scrollPhase = ScrollPhase.idle
	@ObservationIgnored private(set) var isFirstResponder = false
	@ObservationIgnored private(set) var scrollDirection = ScrollDirection.none
	@ObservationIgnored private(set) var scrollGeometry: ScrollGeometry?
	@ObservationIgnored private(set) var visibleViewIDs = [String]()
	@ObservationIgnored private let scrollGeometryPublisher = PassthroughSubject<ScrollGeometry, Never>()
	@ObservationIgnored private let cancelBag = CancelBag()
	@ObservationIgnored let config: ConversationInitializer.Configuration
	@ObservationIgnored weak var delegate: ChatScrollManagerDelegate?
	private(set) var scrollItemQueue: Deque<ScrollPositionItem> = .init()

	init(config: ConversationInitializer.Configuration) {
		self.config = config
		scrollGeometryPublisher
			.removeDuplicates()
			.debounce(for: 0.5, scheduler: DispatchQueue.main)
			.sink { [weak self] value in
				guard let self else { return }
				endScrollViewUpdates(for: value)
			}
			.store(in: cancelBag)
	}

	deinit {
		cancelBag.cancel()
		Log("Deinit")
	}

	var boundsWidth: CGFloat { bottomBarFrame.width }
	let noAnimation: Transaction = {
		var transition = Transaction(animation: nil)
		transition.disablesAnimations = true
		transition.scrollPositionUpdatePreservesVelocity = false
		transition.scrollContentOffsetAdjustmentBehavior = .disabled
		transition.tracksVelocity = false
		return transition
	}()
	private let withAnimation: Transaction = {
		var transition = Transaction(animation: .spring)
		transition.disablesAnimations = false
		transition.scrollPositionUpdatePreservesVelocity = true
		transition.scrollContentOffsetAdjustmentBehavior = .automatic
		transition.tracksVelocity = true
		return transition
	}()
}
// Pagination
extension ChatScrollManager {
	private var canLoadPrevious: Bool {
		updatingState.isNotUpdating &&
		delegate?.canLoadPrevious == true
	}
	var canLoadMore: Bool {
		updatingState.isNotUpdating &&
		delegate?.canLoadMore == true
	}
	private func loadPreviousIfNeeded() {
		guard let msg = delegate?.firstMsg else { return }
		updateLoadingState(.insertingItems(.top))
		delegate?.scrollManager(self, loadPrevious: msg)
	}

	private func loadMoreIfNeeded() {
		guard let msg = delegate?.lastMsg else { return }
		updateLoadingState(.insertingItems(.bottom))
		delegate?.scrollManager(self, loadMore: msg)
	}

	private func loadMsgsIfNeeded(_ newValue: ScrollGeometry) {
		guard updatingState.isNotUpdating && !isFirstResponder else { return }
		let location = newValue.location
		switch location.edge {
		case .top:
			if location.fraction < 0.01 && canLoadPrevious {
				loadPreviousIfNeeded()
			}
		case .bottom:
			if location.fraction < 0.2 && canLoadMore {
				loadMoreIfNeeded()
			}
		}
	}
}
// Events
extension ChatScrollManager {

	func handleScrollPhaseChange(
		_ oldValue: ScrollPhase,
		_ newValue: ScrollPhase,
		_ context: ScrollPhaseChangeContext
	) {
		scrollPhase = newValue
		scrollGeometry = context.geometry
		isScrollingStopped = false
		if !newValue.isScrolling {
			scrolledPosition = context.geometry.scrolledPosition
		}
	}
	func handleScrollGeometryChange(_ oldValue: ScrollGeometry, _ newValue: ScrollGeometry) {
		scrollGeometryPublisher.send(newValue)
		if oldValue.contentSize.width != newValue.contentSize.width {
			return
		}
		if updatingState.isUpdating {
			guard oldValue.contentSize.height != newValue.contentSize.height else {
				scrollGeometry = newValue
				return
			}
			switch updatingState {
			case .insertingItems(let edge):
				switch edge {
				case .top:
					let offsetY = newValue.adjustedOffsetY(from: oldValue)
					adjustNewScrollPosition(newValue, offsetY, additional: -newValue.contentInsets.top)
					updateLoadingState(.notLoading)
				case .bottom:
					scrolledPosition = oldValue.scrolledPosition
					updateLoadingState(.notLoading)
				}
			case .removingItems(let edge):
				switch edge {
				case .top:
					adjustNewScrollPosition(newValue, newValue.adjustedOffsetY(from: oldValue))
					updateLoadingState(.notLoading)
				case .bottom:
					adjustNewScrollPosition(newValue, newValue.visibleRect.minY)
					updateLoadingState(.notLoading)
				}
			case .resetting:
				scroll(to: .offset(yPosition: newValue.bottomMostOffset - newValue.contentInsets.bottom, animated: false))
				updateLoadingState(.notLoading)
			case .appendingItem:
				if oldValue.scrolledPosition.isAroundBottom {
					scroll(to: .bottom(animated: true, duration: 0.15))
				}
				updateLoadingState(.notLoading)
			default:
				break
			}
		} else {
			if scrollPhase == .decelerating {
				loadMsgsIfNeeded(newValue)
			}
		}

		func adjustNewScrollPosition(_ newValue: ScrollGeometry, _ offSetY: CGFloat, additional: CGFloat? = nil) {
			var transition = noAnimation
			if let additional {
				let newY = offSetY + additional
				transition.addAnimationCompletion(criteria: .removed) { [self] in
					var newTransaction = withAnimation
					newTransaction.animation = .spring
					withTransaction(newTransaction) {
						scrollPosition.scrollTo(y: newY)
					}
				}
			}
			withTransaction(transition) {
				scrollPosition.scrollTo(y: offSetY)
			}
		}
	}
	func handleVisibleIDsChange(_ ids: [String]) {
		visibleViewIDs = ids
	}
	func handleBottomBarFrameChange(_ oldValue: CGRect, _ newValue: CGRect) {
		guard oldValue != newValue else { return }
		if bottomBarFrame != newValue {
			if newValue.width != 0 && bottomBarFrame.width != 0 && newValue.width != bottomBarFrame.width {
				scrollPosition.reset()
			}
			if newValue.width != bottomBarFrame.width {
				delegate?.scrollManager(self, didUpdateBoundsWidth: newValue.width)
			}
			bottomBarFrame = newValue
		}
		guard let scrollGeometry, newValue.maxY < oldValue.maxY else {
			isFirstResponder = false
			Haptics.play(.rigid, 0.5)
			return
		}
		isFirstResponder = true
		Haptics.play(.rigid, 0.5)
		guard scrolledPosition != .atBottom else { return }
		let targetY = scrollGeometry.contentOffset.y + (oldValue.maxY - newValue.maxY) + scrollGeometry.contentInsets.top
		scroll(to: .offset(yPosition: targetY, animated: false))
	}
}
// Scrolling
extension ChatScrollManager {
	func queue(to item: ScrollPositionItem) {
		scrollItemQueue.enqueue(item)
	}
	func scroll(to item: ScrollPositionItem) {
		switch item {
		case .offset(let yPosition, let animated, let duration):
			performScroll(animated: animated, duration: duration) {
				self.scrollPosition.scrollTo(y: yPosition)
			}
		case .id(value: let value, let anchor, animated: let animated, let duration):
			performScroll(animated: animated, duration: duration) {
				self.scrollPosition.scrollTo(id: value, anchor: anchor)
			}
		case .bottom(let animated, let duration):
			performScroll(animated: animated, duration: duration) {
				self.scrollPosition.scrollTo(edge: .bottom)
			}
		}
	}

	private func performScroll(
		animated: Bool,
		duration: Double?,
		_ action: () -> Void,
		completion: (@Sendable () -> Void)? = nil
	) {
		var transaction: Transaction = animated ? withAnimation : noAnimation
		if let duration {
			transaction.animation = transaction.animation?.speed(duration)
		}
		if let completion {
			transaction.addAnimationCompletion(criteria: .removed) {
				completion()
			}
		}
		withTransaction(transaction) {
			action()
		}
	}
}
// Conditions
extension ChatScrollManager {
	func updateLoadingState(_ state: ScrollViewUpdatingState) {
		guard updatingState != .initial else { return }
		updatingState = state
	}

	func setHasViewUpdated() {
		updatingState = .notLoading
	}
	func endScrollViewUpdates(for newValue: ScrollGeometry) {
		dequeueIfNeeded()
		scrollGeometry = newValue
		scrolledPosition = newValue.scrolledPosition
		isScrollingStopped = true
		guard updatingState.isNotUpdating && !isFirstResponder else {
			return
		}
		delegate?.scrollManager(self, finalizeScrollViewUpdate: scrolledPosition)
	}
	
	func dequeueIfNeeded() {
		if let item = scrollItemQueue.dequeue() {
			scroll(to: item)
		}
	}
}

extension ScrollPosition {
	public static let userDefined = {
		var position = ScrollPosition()
		position.isPositionedByUser = true
		return position
	}()
	mutating func reset() {
		self = .userDefined
	}
}
