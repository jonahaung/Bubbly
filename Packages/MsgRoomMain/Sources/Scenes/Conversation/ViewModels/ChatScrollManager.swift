//
//  ChatScrollManager.swift
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
protocol ChatScrollManagerDelegate: AnyObject {
	var canLoadPrevious: Bool { get }
	var canLoadMore: Bool { get }
	var lastMessage: Message? { get }
	var firstMessage: Message? { get }
	func scrollManager(_ manager: ChatScrollManager, finalizeScrollViewUpdate position: ScrolledPosition)
	func scrollManager(_ manager: ChatScrollManager, loadPrevious message: Message)
	func scrollManager(_ manager: ChatScrollManager, loadMore message: Message)
	func scrollManager(reloadScrollView manager: ChatScrollManager)
}

@MainActor
@Observable
final class ChatScrollManager: ErrorPresenter {
	private(set) var scrollPosition = ScrollPosition(idType: String.self)
	@ObservationIgnored private(set) var updatingState = ScrollViewUpdateingState.initial
	@ObservationIgnored private(set) var isFirstResponder = false
	@ObservationIgnored private(set) var visibleIDs = [String]()
	@ObservationIgnored private(set) var scrolledPosition = ScrolledPosition.atBottom
	@ObservationIgnored private var scrollPhase = ScrollPhase.idle
	@ObservationIgnored private let cancelBag = CancelBag()
	@ObservationIgnored let layoutCache: MsgsScrollViewLayoutCache
	@ObservationIgnored weak var delegate: ChatScrollManagerDelegate?
	@ObservationIgnored private var scrollItemQueue = Deque<ScrollPositionItem>()
	@ObservationIgnored private let updatePublisher = PassthroughSubject<UUID, Never>()
	@ObservationIgnored private(set) var geometry = VScrollGeometry.empty

	init() {
		layoutCache = .init()
		updatePublisher
			.debounce(for: 0.3, scheduler: RunLoop.main)
			.sink { [weak self] _ in
				guard let self else { return }
				MainActor.assumeIsolated { dequeueIfNeeded() }
			}
			.store(in: cancelBag)
	}

	deinit {
		cancelBag.cancel()
		Log("Deinit")
	}
}

extension ChatScrollManager {
	private var canLoadPrevious: Bool { delegate?.canLoadPrevious == true }
	private var canLoadMore: Bool { delegate?.canLoadMore == true }

	private func loadMessagesIfNeeded(_ newValue: VScrollGeometry) {
		guard updatingState.isNotUpdating, !isFirstResponder else { return }
		let location = newValue.location
		switch location.edge {
		case .top:
			if location.fraction < 0.1, canLoadPrevious {
				guard let message = delegate?.firstMessage else { return }
				updateLoadingState(.insertingItems(.top))
				delegate?.scrollManager(self, loadPrevious: message)
			}
		case .bottom:
			if location.fraction < 0.2, canLoadMore {
				guard let message = delegate?.lastMessage else { return }
				updateLoadingState(.insertingItems(.bottom))
				delegate?.scrollManager(self, loadMore: message)
			}
		}
	}
}

extension ChatScrollManager {
	var isScrolling: Bool { scrollPhase.isScrolling }

	func handleScrollPhaseChange(
		_: ScrollPhase,
		_ new: ScrollPhase,
		_ context: ScrollPhaseChangeContext
	) {
		scrollPhase = new
		scrolledPosition = context.geometry.scrolledPosition
		if new == .idle {
			updatePublisher.send(.init())
		}
	}

	func handleScrollGeometryChange(_ old: VScrollGeometry, _ new: VScrollGeometry) {
		guard updatingState.hasViewLoaded else { return }
		geometry = new
		if updatingState.isUpdating {
			guard old.contentHeight != new.contentHeight else { return }
			switch updatingState {
			case .insertingItems(let edge), .removingItems(let edge):
				switch edge {
				case .top:
					geometry.offsetY = new.adjustedOffsetY(from: old)
					scrollPosition.scrollTo(y: geometry.offsetY)
				case .bottom:
					geometry.offsetY = edge == .top ? new.visibleRect.minY : new.offsetY
					scrollPosition = .init(y: geometry.offsetY)
				}
				updateLoadingState(.notLoading)
			case .appendingItem:
				var transaction = Transaction.withAnimation
				transaction.animation = .interactiveSpring(duration: 0.3)
				transaction.addAnimationCompletion { [weak self] in self?.updateLoadingState(.notLoading) }
				geometry.offsetY = new.bottomMostOffset
				withTransaction(transaction) { scrollPosition.scrollTo(y: geometry.offsetY) }
			case .resetting:
				geometry.offsetY = new.bottomMostOffset
				debounceScroll(to: .offset(yPosition: geometry.offsetY))
				updateLoadingState(.notLoading)
			default:
				geometry.offsetY = new.offsetY
			}
		} else {
			guard old.contentHeight == new.contentHeight else { return }
			if scrollPhase == .decelerating {
				loadMessagesIfNeeded(old)
			}
		}
	}

	func handleVisibleIDsChange(_ ids: [String]) {
		visibleIDs = ids
	}

	func handleBottomBarFrameChange(_ old: CGRect, _ new: CGRect) {
		if !updatingState.hasViewLoaded {
			if old.minX != new.minX, new.minX == 0 {
				setHasViewUpdated()
				setScrollPosition(to: .init(idType: String.self, edge: .bottom))
				return
			}
		}
		guard updatingState.hasViewLoaded else { return }
		if old.width != new.width, old.minX == new.minX {
			delegate?.scrollManager(reloadScrollView: self)
			return
		}
		guard old.height != new.height || old.maxY != new.maxY else { return }
		guard new.maxY < old.maxY else {
			isFirstResponder = false
			return
		}
		isFirstResponder = true
		guard updatingState.isNotUpdating else { return }
		if scrolledPosition == .atBottom { return }
		let targetY = geometry.offsetY + (old.maxY - new.maxY) + geometry.topInset
		if scrollPhase.isScrolling {
			debounceScroll(to: .offset(yPosition: targetY, animated: true, duration: 0.2))
		} else {
			setScrollPosition(to: .init(y: targetY))
		}
	}
}

extension ChatScrollManager {
	func setScrollPosition(to value: ScrollPosition) {
		scrollPosition = value
	}

	func stopScrolling() {
		scrollPosition = .init(y: geometry.offsetY)
	}

	func debounceScroll(to item: ScrollPositionItem) {
		scrollItemQueue.enqueue(item)
		updatePublisher.send(UUID())
	}

	func scroll(to item: ScrollPositionItem, completion: (() -> Void)? = nil) {
		if scrollPhase.isScrolling {
			debounceScroll(to: item)
			return
		}
		switch item {
		case .offset(let value, let animated, let duration):
			performScroll(
				animated: animated,
				duration: duration
			) {
				scrollPosition.scrollTo(
					y: value
				)
			} completion: {
				completion?()
			}
		case .id(let value, let anchor, let animated, let duration):
			performScroll(
				animated: animated,
				duration: duration
			) {
				scrollPosition.scrollTo(
					id: value,
					anchor: anchor
				)
			} completion: {
				completion?()
			}
		case .layoutID(let value, let anchor, let animated, let duration):
			if let layout = layoutCache.layout(for: value) {
				let rect = layout.frame
				let targetY: CGFloat =
					switch anchor {
					case .top:
						rect.minY - geometry.topInset
					case .bottom:
						geometry.targetOffsetY(for: rect)
					case .center:
						rect.midY - geometry.boundsHeight / 4
					default:
						geometry.targetOffsetY(for: rect)
					}
				performScroll(
					animated: animated,
					duration: duration
				) {
					scrollPosition.scrollTo(
						y: targetY
					)
				} completion: {
					completion?()
				}
			}
		case .bottom(let animated, let duration):
			performScroll(
				animated: animated,
				duration: duration
			) {
				scrollPosition.scrollTo(
					edge: .bottom
				)
			} completion: {
				completion?()
			}
		}
	}

	private func dequeueIfNeeded() {
		guard let item = scrollItemQueue.dequeue() else {
			endScrollViewUpdates()
			return
		}
		scroll(to: item)
	}

	private func performScroll(
		animated: Bool,
		duration: Double?,
		_ action: () -> Void,
		completion: @MainActor @escaping () -> Void
	) {
		var transaction = animated ? Transaction.withAnimation : .withoutAnimation
		if let duration {
			transaction.animation = transaction.animation?.speed(duration)
		}
		transaction.addAnimationCompletion(criteria: .removed) { [weak self] in
			guard let self else { return }
			if let duration {
				DispatchQueue.delay(duration) { [weak self] in
					guard let self else { return }
					completion()
					dequeueIfNeeded()
				}
			} else {
				DispatchQueue.delay { [weak self] in
					guard let self else { return }
					completion()
					dequeueIfNeeded()
				}
			}
		}
		withTransaction(transaction) { action() }
	}
}

extension ChatScrollManager {
	func updateLoadingState(_ state: ScrollViewUpdateingState) {
		guard updatingState != .initial else { return }
		updatingState = state
	}

	private func setHasViewUpdated() {
		updatingState = .notLoading
	}

	private func endScrollViewUpdates() {
		delegate?.scrollManager(self, finalizeScrollViewUpdate: scrolledPosition)
	}
}
