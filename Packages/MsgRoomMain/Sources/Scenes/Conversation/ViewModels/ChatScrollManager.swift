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
	private(set) var updatingState = ScrollViewUpdateingState.initial
	@ObservationIgnored private(set) var isFirstResponder = false
	@ObservationIgnored private(set) var visibleViewIDs = [String]()
	private(set) var scrolledPosition = ScrolledPosition.atBottom
	@ObservationIgnored private var scrollPhase = ScrollPhase.idle
	@ObservationIgnored private let geometryPublisher = PassthroughSubject<ScrollGeometry, Never>()
	@ObservationIgnored private let cancelBag = CancelBag()
	@ObservationIgnored private var scrollGeometry: ScrollGeometry = .empty
	@ObservationIgnored let layoutCache: ChatCache
	@ObservationIgnored weak var delegate: ChatScrollManagerDelegate?

	init() {
		layoutCache = .init()
		geometryPublisher
			.removeDuplicates()
			.debounce(for: 0.3, scheduler: RunLoop.main)
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
		updatingState.isNotUpdating &&
		delegate?.canLoadPrevious == true
	}
	var canLoadMore: Bool {
		updatingState.isNotUpdating &&
		delegate?.canLoadMore == true
	}

	private func loadMsgsIfNeeded(_ newValue: ScrollGeometry) {
		guard updatingState.isNotUpdating && !isFirstResponder else { return }
		let location = newValue.location
		switch location.edge {
		case .top:
			if location.fraction < 0.001 && canLoadPrevious {
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
		scrollPhase = newValue

	}
	func getScrollGeometry() -> ScrollGeometry {
		scrollGeometry
	}
	func handleScrollGeometryChange(_ oldValue: ScrollGeometry, _ newValue: ScrollGeometry) {
		geometryPublisher.send(newValue)
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
		Haptics.play(.soft, 0.9)
		guard !scrolledPosition.nearBottom else { return }
		let targetY = scrollGeometry.contentOffset.y + (oldValue.maxY - newValue.maxY) + scrollGeometry.contentInsets.top
		scrollPosition = .init(y: targetY)
	}
}
// Scrolling
extension ChatScrollManager {
	func setScrollPosition(to position: ScrollPosition) {
		scrollPosition = position
	}
	func scroll(to layoutID: String, _ anchor: UnitPoint? = .bottom, animated: Bool = true, duration: Double? = 0.2, completion: (@Sendable () -> Void)? = nil) {
		if let layout = layoutCache.layout.layout(for: layoutID) {
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
	func scroll(to item: ScrollPositionItem, completion: (@Sendable () -> Void)? = nil) {

		switch item {
		case .offset(let yPosition, let animated, let duration):
			performScroll(animated: animated, duration: duration) {
				self.scrollPosition.scrollTo(y: yPosition)
			} completion: {
				completion?()
			}
		case .id(value: let value, let anchor, animated: let animated, let duration):
			scroll(to: value, anchor, animated: animated, duration: duration) {
				completion?()
			}
		case .bottom(let animated, let duration):
			let yPosition = scrollGeometry.bottomMostOffset
			performScroll(animated: animated, duration: duration) {
				self.scrollPosition.scrollTo(y: yPosition)
			} completion: {
				completion?()
			}
		}
	}
	private func performScroll(
		animated: Bool,
		duration: Double?,
		_ action: () -> Void,
		completion: sending (@Sendable () -> Void)? = nil
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
		scrollGeometry = newValue
		scrolledPosition = newValue.scrolledPosition
		updateLoadingState(.notLoading)
		delegate?.scrollManager(self, finalizeScrollViewUpdate: scrolledPosition)
	}
}
