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
	var lastMsg: Message? { get }
	var firstMsg: Message? { get }
	func scrollManager(_ manager: ChatScrollManager, finalizeScrollViewUpdate position: ScrolledPosition)
	func scrollManager(_ manager: ChatScrollManager, loadPrevious msg: Message)
	func scrollManager(_ manager: ChatScrollManager, loadMore msg: Message)
}

@MainActor
@Observable
final class ChatScrollManager: ErrorPresenter {

	private(set) var scrollPosition = ScrollPosition.userDefined
	private(set) var isHidden = true
	@ObservationIgnored private(set) var updatingState = ScrollViewUpdateingState.initial
	@ObservationIgnored private(set) var isFirstResponder = false
	@ObservationIgnored private(set) var visibleViewIDs = [String]()
	@ObservationIgnored private(set) var scrolledPosition = ScrolledPosition.atBottom
	@ObservationIgnored private var scrollPhase = ScrollPhase.idle
	@ObservationIgnored private let geometryPublisher = PassthroughSubject<ScrollGeometry, Never>()
	@ObservationIgnored private let cancelBag = CancelBag()
	@ObservationIgnored private var scrollGeometry: ScrollGeometry = .empty
	@ObservationIgnored let layoutCache: MsgsScrollViewLayoutCache
	@ObservationIgnored weak var delegate: ChatScrollManagerDelegate?
	@ObservationIgnored private var scrollItemQueue = Deque<ScrollPositionItem>()
	private(set) var isScrolling = false
	private(set) var offsetY = CGFloat(0)

	init() {
		layoutCache = .init()
		geometryPublisher
			.removeDuplicates()
			.debounce(for: 0.7, scheduler: RunLoop.main)
			.sink { [weak self] value in
				guard let self else { return }
				MainActor.assumeIsolated {
					endScrollViewUpdates(for: value)
				}
			}
			.store(in: cancelBag)
	}

	deinit {
		cancelBag.cancel()
		Log("Deinit")
	}
}
// Pagination
extension ChatScrollManager {
	private var canLoadPrevious: Bool {
		delegate?.canLoadPrevious == true
	}
	private var canLoadMore: Bool {
		delegate?.canLoadMore == true
	}

	private func loadMsgsIfNeeded(_ newValue: ScrollGeometry) {
		guard updatingState.isNotUpdating && !isFirstResponder else { return }
		let location = newValue.location
		switch location.edge {
		case .top:
			if location.fraction < 0.1 && canLoadPrevious {
				guard let msg = delegate?.firstMsg else { return }
				updateLoadingState(.insertingItems(.top))
				delegate?.scrollManager(self, loadPrevious: msg)
			}
		case .bottom:
			if location.fraction < 0.2 && canLoadMore {
				guard let msg = delegate?.lastMsg else { return }
				updateLoadingState(.insertingItems(.bottom))
				delegate?.scrollManager(self, loadMore: msg)
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
		let geometry = context.geometry
		if newValue == .idle {
			scrollGeometry = geometry
			scrolledPosition = geometry.scrolledPosition
			geometryPublisher.send(geometry)
		} else {
			if !isScrolling {
				isScrolling = true
			}
		}
		scrollPhase = newValue
	}
	func getScrollGeometry() -> ScrollGeometry {
		scrollGeometry
	}
	func handleScrollGeometryChange(_ oldValue: ScrollGeometry, _ newValue: ScrollGeometry) {
		offsetY = newValue.contentOffset.y
		if updatingState.isUpdating {
			guard oldValue.contentSize.height != newValue.contentSize.height else {
				return
			}
			switch updatingState {
			case .insertingItems(let edge):
				switch edge {
				case .top:
					let offsetY = newValue.adjustedOffsetY(from: oldValue)
					scrollPosition.scrollTo(y: offsetY)
					updateLoadingState(.notLoading)
				case .bottom:
					updateLoadingState(.notLoading)
				}
			case .removingItems(let edge):
				switch edge {
				case .top:
					let offsetY = newValue.adjustedOffsetY(from: oldValue)
					scrollPosition.scrollTo(y: offsetY)
					updateLoadingState(.notLoading)
				case .bottom:
					scrollPosition = .init(y: newValue.visibleRect.minY)
					updateLoadingState(.notLoading)
				}
			case .appendingItem(let id):
				if oldValue.scrolledPosition.nearBottom {
					scroll(to: id, .bottom, animated: true) { [weak self] in
						guard let self else { return }
						MainActor.assumeIsolated {
							self.updateLoadingState(.notLoading)
						}
					}
				} else {
					updateLoadingState(.notLoading)
				}
			case .resetting:
				updateLoadingState(.notLoading)
			default:
				break
			}
		} else {
			guard oldValue.contentSize.height == newValue.contentSize.height else {
				return
			}
			if scrollPhase == .decelerating {
				loadMsgsIfNeeded(oldValue)
			}
		}
	}
	func handleVisibleIDsChange(_ ids: [String]) {
		visibleViewIDs = ids
	}
	func handleBottomBarFrameChange(_ oldValue: CGRect, _ newValue: CGRect) {
		guard oldValue.height != newValue.height || oldValue.maxY != newValue.maxY else {
			return
		}
		if isHidden {
			isHidden = false
		}
		guard newValue.maxY < oldValue.maxY else {
			isFirstResponder = false
			return
		}
		isFirstResponder = true
		guard !scrollPhase.isScrolling && updatingState.isNotUpdating else { return }
		guard scrolledPosition != .atBottom else { return }
		let targetY = offsetY + (oldValue.maxY - newValue.maxY) + scrollGeometry.contentInsets.top
		scroll(to: .offset(yPosition: targetY, animated: false))
	}
}
// Scrolling
extension ChatScrollManager {
	func setScrollPosition(to position: ScrollPosition) {
		scrollPosition = position
	}
	func scroll(to layoutID: String, _ anchor: UnitPoint? = .bottom, animated: Bool = true, duration: Double? = 0.2, completion: (() -> Void)? = nil) {
		if let layout = layoutCache.layout(for: layoutID) {
			let rect = layout.frame
			let offsetY: CGFloat
			switch anchor {
			case .top:
				offsetY = rect.minY - scrollGeometry.contentInsets.top
			case .bottom:
				offsetY = rect.minY - scrollGeometry.bounds.height + rect.height + ChatLayoutConstants.bottomBarHeight + 1
			case .center:
				offsetY = rect.midY - scrollGeometry.bounds.midY/2
			default:
				offsetY = rect.minY - scrollGeometry.bounds.height + rect.height + ChatLayoutConstants.bottomBarHeight - 1
			}
			performScroll(animated: animated, duration: duration) {
				scrollPosition.scrollTo(y: offsetY)
			} completion: {
				completion?()
			}
		}
	}
	func scroll(to item: ScrollPositionItem, completion: (() -> Void)? = nil) {
		switch item {
		case .offset(let yPosition, let animated, let duration):
			performScroll(animated: animated, duration: duration) {
				self.scrollPosition.scrollTo(y: yPosition)
			} completion: { [weak self] in
				completion?()
				self?.dequeueIfNeeded()
			}
		case .id(value: let value, let anchor, animated: let animated, let duration):
			scroll(to: value, anchor, animated: animated, duration: duration) {
				completion?()
				self.dequeueIfNeeded()
			}
		case .bottom(let animated, let duration):
			let yPosition = scrollGeometry.bottomMostOffset
			performScroll(animated: animated, duration: duration) {
				self.scrollPosition.scrollTo(y: yPosition)
			} completion: { [weak self] in
				completion?()
				self?.dequeueIfNeeded()
			}
		}
	}

	private func dequeueIfNeeded() {
		guard let item = scrollItemQueue.dequeue() else { return }
		scroll(to: item)
	}
	private func performScroll(
		animated: Bool,
		duration: Double?,
		_ action: () -> Void,
		completion: (() -> Void)? = nil
	) {
		var transaction = animated ? Transaction.withAnimation : .withoutAnimation
		if let duration {
			transaction.animation = transaction.animation?.speed(duration)
		}
		if let completion {
			transaction.addAnimationCompletion(criteria: .removed) {
				if let duration {
					DispatchQueue.delay(duration) {
						completion()
					}
				} else {
					DispatchQueue.delay {
						completion()
					}
				}
			}
		}
		withTransaction(transaction) {
			action()
		}
	}
}
// Conditions
extension ChatScrollManager {
	func updateLoadingState(_ state: ScrollViewUpdateingState) {
		guard updatingState != .initial else { return }
		updatingState = state
	}
	func setHasViewUpdated() {
		updatingState = .notLoading
	}
	private func endScrollViewUpdates(for newValue: ScrollGeometry) {
		guard !scrollPhase.isScrolling else {
			return
		}
		dequeueIfNeeded()
		scrollItemQueue.removeAll()
		isScrolling = false
		delegate?.scrollManager(self, finalizeScrollViewUpdate: scrolledPosition)
	}
}
