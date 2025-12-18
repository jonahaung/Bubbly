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
	private(set) var scrollPosition = ScrollPosition()
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
			.debounce(for: 0.5, scheduler: RunLoop.main)
			.sink { [weak self] _ in
				guard let self else { return }
				MainActor.assumeIsolated {
					guard !isScrolling else {
						updatePublisher.send(.init())
						return
					}
					endScrollViewUpdates()
				}
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

	func handleScrollPhaseChange(_: ScrollPhase, _ newValue: ScrollPhase, _ context: ScrollPhaseChangeContext) {
		scrollPhase = newValue
		scrolledPosition = context.geometry.scrolledPosition
		switch newValue {
		case .idle:
			updatePublisher.send(.init())
		default:
			break
		}
	}

	func handleScrollGeometryChange(_ oldValue: VScrollGeometry, _ newValue: VScrollGeometry) {
		guard updatingState.hasViewLoaded else {
			return
		}
		var vGeometry = newValue
		if updatingState.isUpdating {
			guard oldValue.contentHeight != newValue.contentHeight else { return }
			switch updatingState {
			case let .insertingItems(edge), let .removingItems(edge):
				switch edge {
				case .top:
					vGeometry.offsetY = newValue.adjustedOffsetY(from: oldValue)
					scrollPosition.scrollTo(y: vGeometry.offsetY)
				case .bottom:
					vGeometry.offsetY = edge == .top ? newValue.visibleRect.minY : newValue.offsetY
					scrollPosition = .init(y: vGeometry.offsetY)
				}
				updateLoadingState(.notLoading)
			case .appendingItem:
				var transaction = Transaction.withAnimation
				transaction.animation = .interactiveSpring(duration: 0.3)
				transaction.addAnimationCompletion { [weak self] in self?.updateLoadingState(.notLoading) }
				vGeometry.offsetY = newValue.bottomMostOffset
				withTransaction(transaction) { scrollPosition.scrollTo(y: vGeometry.offsetY) }
			case .resetting:
				vGeometry.offsetY = newValue.bottomMostOffset
				setScrollPosition(to: .init(y: vGeometry.offsetY - vGeometry.boundsHeight/2))
				debounceScroll(to: .bottom())
				updateLoadingState(.notLoading)
			default:
				vGeometry.offsetY = newValue.offsetY
			}
			updatePublisher.send(.init())
		} else {
			guard oldValue.contentHeight == newValue.contentHeight else { return }
			if scrollPhase == .decelerating {
				loadMessagesIfNeeded(oldValue)
			}
		}
		self.geometry = vGeometry
	}

	func handleVisibleIDsChange(_ ids: [String]) {
		visibleIDs = ids
	}

	func handleBottomBarFrameChange(_ oldValue: CGRect, _ newValue: CGRect) {
		guard updatingState.hasViewLoaded else {
			if oldValue.minX != newValue.minX, newValue.minX == 0, scrolledPosition != .atBottom {
				setScrollPosition(to: .init(idType: String.self, edge: .bottom))
				scrolledPosition = .atBottom
				return
			}
			return
		}
		if oldValue.width != newValue.width {
			if let id = visibleIDs.last {
				setScrollPosition(to: .init(id: id, anchor: .bottom))
				delegate?.scrollManager(reloadScrollView: self)
			}
			return
		}
		guard oldValue.height != newValue.height || oldValue.maxY != newValue.maxY else { return }
		guard newValue.maxY < oldValue.maxY else {
			isFirstResponder = false
			return
		}
		isFirstResponder = true
		guard updatingState.isNotUpdating else { return }
		if scrolledPosition == .atBottom { return }
		let targetY = geometry.offsetY + (oldValue.maxY - newValue.maxY) + geometry.topInset
		if scrollPhase.isScrolling {
			debounceScroll(to: .offset(yPosition: targetY, animated: true, duration: 0.2))
		} else {
			setScrollPosition(to: .init(y: targetY))
		}
	}
}

extension ChatScrollManager {
	func setScrollPosition(to newValue: ScrollPosition) {
		scrollPosition = newValue
	}

	func stopScrolling() {
		setScrollPosition(to: .init(y: geometry.offsetY))
	}

	func debounceScroll(to newValue: ScrollPositionItem) {
		scrollItemQueue.enqueue(newValue)
		updatePublisher.send(UUID())
	}

	private func scrollIfNeeded() {
		guard let newValue = scrollItemQueue.dequeue() else {
			return
		}
		scroll(to: newValue)
	}

	func scroll(to newValue: ScrollPositionItem) {
		if scrollPhase.isScrolling {
			debounceScroll(to: newValue)
			return
		}
		switch newValue {
		case let .offset(value, animated, duration):
			performScroll(animated: animated, duration: duration) {
				scrollPosition.scrollTo(
					y: value
				)
			}
		case let .id(value, anchor, animated, duration):
			performScroll(animated: animated, duration: duration) {
				scrollPosition.scrollTo(
					id: value,
					anchor: anchor
				)
			}
		case let .layoutID(value, anchor, animated, duration):
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
				performScroll(animated: animated, duration: duration) {
					scrollPosition.scrollTo(
						y: targetY
					)
				}
			}
		case let .bottom(animated, duration):
			performScroll(animated: animated, duration: duration) {
				scrollPosition.scrollTo(
					edge: .bottom
				)
			}
		}
	}

	private func performScroll(animated: Bool, duration: Double?, _ action: () -> Void) {
		var transaction = animated ? Transaction.withAnimation : .withoutAnimation
		if let duration {
			transaction.animation = transaction.animation?.speed(duration)
		}
		transaction.addAnimationCompletion(criteria: .removed) { [weak self] in
			guard let self else { return }
			if let duration {
				DispatchQueue.delay(duration) { [weak self] in
					guard let self else { return }
					scrollIfNeeded()
				}
			} else {
				DispatchQueue.delay { [weak self] in
					guard let self else { return }
					scrollIfNeeded()
				}
			}
		}
		withTransaction(transaction) { action() }
	}
}

extension ChatScrollManager {
	func updateLoadingState(_ newValue: ScrollViewUpdateingState) {
		guard updatingState != .initial else { return }
		updatingState = newValue
	}

	func setHasViewUpdated() {
		updatingState = .notLoading
	}

	private func endScrollViewUpdates() {
		delegate?.scrollManager(self, finalizeScrollViewUpdate: scrolledPosition)
		scrollIfNeeded()
	}
}
